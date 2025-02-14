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
            print('rrrrrrrrrrrrppppppppppppppppppppppppppppppppppppppppp');
            String img = data['svg'];
            emit(GameReceivePic(svg_img: img ));
          }
        }

    } else {
      emit(GameErr(err: 'Unexpected server response.'));
    }
  }

  void sendSVG(String svg_file,{String action = 'send svg'}){

    final message = {
      'type':action,
      'svg':svg_file,
      'id':uid
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