abstract class OnevsoneState {}

class OnevsOneInit extends OnevsoneState {}

class OnevsOneWait extends OnevsoneState {}

class OnevsOnePlay extends OnevsoneState {}

class OnevsOneStart extends OnevsoneState {
  final String prompt;
  final String ucm;

  OnevsOneStart( {required this.prompt,required this.ucm,});
}

class OnevsOneWin extends OnevsoneState {}

class OnevsOneLoss extends  OnevsoneState {}

class OnevsOneTimeout extends OnevsoneState {}

class OnevsOneEnd extends OnevsoneState {}

class OnevsOneErr extends OnevsoneState {
  final String err;

  OnevsOneErr({required this.err});
}
