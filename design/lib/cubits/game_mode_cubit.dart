import 'package:flutter_bloc/flutter_bloc.dart';

enum GameMode { offline, online, multiplayer }

class GameModeCubit extends Cubit<GameMode?> {
  GameModeCubit() : super(null);

  void selectMode(GameMode mode) => emit(mode);
}

