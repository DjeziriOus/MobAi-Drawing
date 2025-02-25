import 'dart:convert';

import 'package:design/screens/game/logic/game_state.dart';
import 'package:design/utils/socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GameCubit extends Cubit<GameState>{
  GameCubit(this.channel, this.streamSocket, this.uid):super(GameStart()){
    
      streamSocket.getResponse.listen((data) {
      if (isClosed) return; // Prevent emitting after close

      if (data == 'disconnect') {
        print('Disconnected from the server.');
        emit(LeaveGame());
      }else if(data=='game start'){
        print('start game............');
      }
       else {
        handleServerResponse(data);
      }
    });
  }

    final WebSocketChannel channel ;
   final StreamSocket streamSocket;
   final String uid;



    void handleServerResponse(dynamic data) {
    if (isClosed) return; // Prevent emitting after close

    if (data is Map<String, dynamic>) {
        if (data['type']=='send svg'){
          String sid = data['sid'];
          if (sid!=uid){
            
            String img = data['svg'];
            emit(GameReceivePic(svg_img: img ));
          }
        } else if(data['type']=='wrong_guess'){
          String wgid = data['id'];
          if (wgid==uid){
         emit(WrongResponse());}
        }else if (data['type']=='player_won'){
          print('lllllllllllllllllllllllllllllllllllwwwwwwwwwwwwwwwwwwwwwwwwww');
          print('Player won: ${data['id']}');
          String wid = data['id'];
          if (wid==uid){
            emit(PlayerWon(win: true));
          }else{
            emit(PlayerWon(win: false));
          }
        }else if (data['type']=='time_finished'){
          emit(GameOver());
        }

    } else {
      emit(GameErr(err: 'Unexpected server response.'));
    }
  }

  void sendGuess(String guess){

    final message = {
      'type':'guess',
      'guess':guess,
      'id':uid
    };
    channel.sink.add(jsonEncode(message));
  }

  void sendSVG(String svg_file,{String action = 'send svg'}){

    final message = {
      'type':action,
      'svg':svg_file,
      'id':uid
    };
    channel.sink.add(jsonEncode(message));
  }
  
  void sendTimeout(){
    final message = {
      'type':'timeout',
      
    };
    channel.sink.add(jsonEncode(message));
  }

  Future<void> close() {
    print('Closing GameCubit...');
    channel.sink.close();
    streamSocket.dispose();
    return super.close();
  }



}