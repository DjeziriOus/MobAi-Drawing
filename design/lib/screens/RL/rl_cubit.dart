import 'dart:convert';

import 'package:design/screens/RL/rl_state.dart';
import 'package:design/utils/socket.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RlCubit extends Cubit<RLState>{

  
  RlCubit(this.uid) : super(RLInit()){
    print('Initializing RoomCubit...');
    emit(RLloading());
    setSocket();
  }


  final String uid;
  final StreamSocket streamSocket = StreamSocket();
  late WebSocketChannel channel;
  String? prompt;
  int time = 0;

    void setSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:3000'),
    );
    connectAndListen();
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
          emit(RLErr(err: 'Failed to parse server response: $e'));
        }
      }
    }, onDone: () {
      print('WebSocket connection closed.');
      streamSocket.addResponse('disconnect');
    }, onError: (error) {
      print('WebSocket error: $error');
      if (!isClosed) {
        emit(RLErr(err: 'WebSocket error: $error'));
      }
    });
  }

  

    void handleServerResponse(dynamic data) {
    if (isClosed) return; // Prevent emitting after close

    if (data is Map<String, dynamic>) {
      if ( data['type'] == 'prompt_start') {
        final payload = data['payload'];
        final String prompt = payload['prompt'];
        final int level = payload['level'];

        emit(RLStart(prompt: prompt, level: level));
        
      }else if (data['type'] == 'ai_guessed') {
        String imgClass = data['guess'];
        int acc = data['accuracy'];
        
        print('AI Guess received: $imgClass with accuracy $acc');
        emit(RLDescription(description: "$imgClass with accuracy $acc"));

        if (imgClass == prompt) {
          announceWin(accuracy: acc);
          emit(RLEnd());
        }
      }

    } else {
      emit(RLErr(err: 'Unexpected server response.'));
    }


  }

  void sendSVG(String svg_file, {String action = 'send pic'}) {
    final message = {'type': action, 'svg': svg_file, 'id': uid};
    channel.sink.add(jsonEncode(message));
  }

  void announceWin({String action = 'offline finish',int accuracy = 0}) {
    final message = {
      'type':action,
      'time': time,
      'id':uid,
      'acccuracy':accuracy

    };
    channel.sink.add(jsonEncode(message));
  }


 
}