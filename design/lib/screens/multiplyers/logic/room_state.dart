import 'package:design/utils/socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class RoomState {}

class RoomInit extends RoomState {}

class RoomLoading extends RoomState {}

class EnterRoom extends RoomState {
  final bool isCreator;
  final String roomID;

  EnterRoom({required this.isCreator,required this.roomID});
}

class RoomErr extends RoomState{
  final String err;

  RoomErr({required this.err});
}

class RoomLeave extends RoomState {}

class StartGame extends RoomState {
  final String roomID;
  final bool isDrawer;
  final StreamSocket streamSocket;
  final WebSocketChannel channel;
  final String uid;


  StartGame( {required this.streamSocket,required this.channel,required this.roomID,required this.isDrawer,required this.uid});
}



