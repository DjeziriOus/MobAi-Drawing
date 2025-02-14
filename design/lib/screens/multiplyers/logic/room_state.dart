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

  StartGame({required this.roomID});
}



