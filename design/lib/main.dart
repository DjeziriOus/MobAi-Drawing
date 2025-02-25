import 'package:design/cubits/game_mode_cubit.dart';
import 'package:design/screens/multiplayer_room_screen.dart';
import 'package:design/screens/multiplyers/view/multip_choice.dart';
import 'package:design/screens/offline_game_screen.dart';
import 'package:design/screens/oneVsOne/logic/oneVsOne_cubit.dart';
import 'package:design/screens/online_game_screen.dart';
import 'package:design/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Guess Drawing Challenge',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: BlocProvider(
        create: (context) => GameModeCubit(),
        child: const WelcomeScreen(),
      ),
      routes: {
        '/offline': (context) => const OfflineGameScreen(),
        '/online': (context) => BlocProvider(
              create: (context) =>
                  OnevsoneCubit("2"),
              child: OnlineGameScreen(),
            ),
        '/multiplayer': (context) => const MultiplayerRoomScreen(),
        '/multiple': (context) => const MultipChoice()
      },
    );
  }
}
