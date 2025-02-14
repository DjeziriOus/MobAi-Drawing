import 'dart:convert';
import 'package:design/screens/multiplyers/logic/room_state.dart';
import 'package:design/utils/socket.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RoomCubit extends Cubit<RoomState> {
  RoomCubit(this.isCreator, this.uid, {this.enteredRoomId}) : super(RoomInit()) {
    print('Initializing RoomCubit...');
    emit(RoomLoading());
    setSocket();
    
    streamSocket.getResponse.listen((data) {
      if (isClosed) return; // Prevent emitting after close

      if (data == 'disconnect') {
        print('Disconnected from the server.');
        emit(RoomLeave());
      } else {
        handleServerResponse(data);
      }
    });
  }

  final bool isCreator;
  final String uid;
  final String? enteredRoomId;
  final StreamSocket streamSocket = StreamSocket();
  late WebSocketChannel channel;
  String? roomId;

  void setSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://10.80.4.193:8000'),
    );
    connectAndListen();
    if(isCreator){
       createRoomID();
    }else{
      roomId = enteredRoomId;
      sendRoomId();
    }
  }

  void connectAndListen() {
    print('Connecting and listening to WebSocket...');
    channel.stream.listen((data) {
      print('Received data from server: $data');
      try {
        final parsedData = jsonDecode(data);
        streamSocket.addResponse(parsedData);
      } catch (e) {
        print('Failed to parse server response: $e');
        if (!isClosed) {
          emit(RoomErr(err: 'Failed to parse server response: $e'));
        }
      }
    }, onDone: () {
      print('WebSocket connection closed.');
      streamSocket.addResponse('disconnect');
    }, onError: (error) {
      print('WebSocket error: $error');
      if (!isClosed) {
        emit(RoomErr(err: 'WebSocket error: $error'));
      }
    });
  }

  void handleServerResponse(dynamic data) {
    if (isClosed) return; // Prevent emitting after close

    if (data is Map<String, dynamic>) {
      if (isCreator && data['type'] == 'party_created') {
        final payload = data['payload'];
        // Room created successfully
        roomId = payload['code'];
        print('Rooooooooom id ${roomId}');
        emit(EnterRoom(isCreator: true, roomID: roomId!));
      } else if (!isCreator && data['message'] != null) {
        // Joined room successfully
        emit(EnterRoom(isCreator: false, roomID: roomId!));
      }
    } else {
      emit(RoomErr(err: 'Unexpected server response.'));
    }
  }


  void createRoomID({String type = 'create_room'}) {
    final message = {
      'type': type,
      'id':10
    };
    channel.sink.add(jsonEncode(message));
  }

  void sendRoomId({String action = 'join_room'}) {
    final message = {
      'type':action,
      'payload': int.parse(roomId!),
      'id':uid

    };
    channel.sink.add(jsonEncode(message));
  }

  @override
  Future<void> close() {
    print('Closing RoomCubit...');
    channel.sink.close();
    streamSocket.dispose();
    return super.close();
  }
}
