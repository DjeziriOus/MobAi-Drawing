abstract class RLState {}


class RLInit extends RLState {}

class RLloading extends RLState {}

class RLStart extends RLState {
  final String prompt;
  final int level;

  RLStart({required this.level,required this.prompt});
}

class RLEnd extends RLState {}


class RLErr extends RLState {
  final String err;

  RLErr({required this.err});
}

class RLDescription extends RLState{
  final String description;

  RLDescription({required this.description});
}




