import 'dart:convert';
import 'package:design/screens/multiplyers/logic/room_state.dart';
import 'package:design/utils/socket.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


class RoomCubit extends Cubit<RoomState> {
  RoomCubit(this.isCreator, this.uid, {this.enteredRoomId})
      : super(RoomInit()) {
    emit(RoomLoading());
    setSocket();
    streamSocket.getResponse.listen((data) {
      if (data == 'disconnect') {
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
      Uri.parse('ws://10.0.2.2:8000/ws/room/'),
    );
    connectAndListen();
  }

  void connectAndListen() {
    channel.stream.listen((data) {
      try {
        final parsedData = jsonDecode(data);
        streamSocket.addResponse(parsedData);
      } catch (e) {
        emit(RoomErr(err: 'Failed to parse server response: $e'));
      }
    }, onDone: () {
      streamSocket.addResponse('disconnect');
    }, onError: (error) {
      emit(RoomErr(err: 'WebSocket error: $error'));
    });
  }

  void handleServerResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (isCreator && data['room_id'] != null) {
        // Room created successfully
        roomId = data['room_id'];
        emit(EnterRoom(isCreator: true, roomID: roomId!));
      } else if (!isCreator && data['message'] != null) {
        // Joined room successfully
        emit(EnterRoom(isCreator: false, roomID: roomId!));
      }
    } else {
      emit(RoomErr(err: 'Unexpected server response.'));
    }
  }

  void sendRoomId({String action = 'join'}) {
    final message = {
      'action': action,
      'room_id': isCreator ? null : enteredRoomId,
      'uid': uid,
    };
    channel.sink.add(jsonEncode(message));
  }

  @override
  Future<void> close() {
    channel.sink.close();
    streamSocket.dispose();
    return super.close();
  }
}
