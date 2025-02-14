abstract class GameState {}

class GameStart extends GameState {}

class GameLoading extends GameState {}

class GameReceivePic extends GameState {
  final String svg_img;

  GameReceivePic({required this.svg_img});
}

class GameOver extends GameState {}

class LeaveGame extends GameState {}

class GameErr extends GameState{
  final String err;

  GameErr({required this.err});
}
