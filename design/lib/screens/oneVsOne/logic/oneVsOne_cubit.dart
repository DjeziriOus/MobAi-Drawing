import 'dart:convert';

import 'package:design/screens/oneVsOne/logic/oneVsOne_state.dart';
import 'package:design/utils/socket.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OnevsoneCubit  extends Cubit<OnevsoneState>{
  OnevsoneCubit(this.uid):super(OnevsOneInit()){
    print('Initializing OneVsOneCubit...');
    emit(OnevsOneWait());
    setSocket();  
    streamSocket.getResponse.listen((data) {
      if (isClosed) return; 

      if (data == 'disconnect') {
        print('Disconnected from the server.');
        
      }else if(data=='game start'){
        
      }
       else {
        handleServerResponse(data);
      }
    });

  }

    final StreamSocket streamSocket = StreamSocket();
    late WebSocketChannel channel;
    final String uid;
    late String ucm;
    late String prompt;


    void setSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:3000'),
    );
    connectAndListen();
    find_room();
  }

  void sendSVG(String svg_file,{String action = 'send pic'}){
    print('sssssssssssenennnnnnnnnnnnnnnnnnnd');
    print(svg_file);

    final message = {
      'type':action,
      'svg':svg_file,
      'id':uid
    };
    channel.sink.add(jsonEncode(message));
  }

  void find_room({String type = 'find room'}) {
    final message = {
      'type': type,
      'id':uid,
    };
    channel.sink.add(jsonEncode(message));
  }

  void announceWin({String type='success'}){
    final message = {
      'type': type,
      'id':uid,
      'lid':ucm
    };
    channel.sink.add(jsonEncode(message));
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

      }
    }, onDone: () {
      print('WebSocket connection closed.');
      streamSocket.addResponse('disconnect');
    }, onError: (error) {
      print('WebSocket error: $error');
      if (!isClosed) {
        emit(OnevsOneErr(err: 'WebSocket error: $error'));
      }
    });
  }




    void handleServerResponse(dynamic data) {
    if (isClosed) return; // Prevent emitting after close

    if (data is Map<String, dynamic>) {
      if (data['type'] == '1vs_response') {
         ucm = data['party']['id1']==uid?data['party']['id2']:data['party']['id1'];
         prompt = data['party']['prompt'];
        print('sssssssssssssssssssssssssssss');
        emit(OnevsOneStart(prompt: prompt, ucm: ucm));
        
        
       
      } else if (data['type'] == 'ai_guessed') {
        String imgClass = data['guess'];
        if (imgClass == prompt) {
            announceWin();
          emit(OnevsOneWin());
        }
      }else if (data['type']=='loser'){
        String lid = data['lid'];
        if (lid==uid){
          emit(OnevsOneLoss());
        }
      }

    } else {
      emit(OnevsOneErr(err: 'Unexpected server response.'));
    }
  }


  
  @override
  Future<void> close() {
    print('Closing OneVsOneCubit...');
    channel.sink.close();
    streamSocket.dispose();
    return super.close();
  }

}