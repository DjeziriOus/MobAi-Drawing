import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/game_mode_cubit.dart';
import '../widgets/splash_header.dart';
import '../widgets/mode_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade900, Colors.purple.shade800],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SplashHeader(),
                    const SizedBox(height: 60),
                    ModeButton(
                      icon: Icons.person,
                      label: 'Offline Mode',
                      onPressed: () => _navigateToMode(context, GameMode.offline),
                    ),
                    const SizedBox(height: 20),
                    ModeButton(
                      icon: Icons.people,
                      label: 'Online Mode',
                      onPressed: () => _navigateToMode(context, GameMode.online),
                    ),
                    const SizedBox(height: 20),
                    ModeButton(
                      icon: Icons.groups,
                      label: 'Multiplayer Room',
                      onPressed: () => _navigateToMode(context, GameMode.multiple),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMode(BuildContext context, GameMode mode) {
    context.read<GameModeCubit>().selectMode(mode);
    switch (mode) {
      case GameMode.offline:
        Navigator.pushNamed(context, '/offline');
        break;
      case GameMode.online:
        Navigator.pushNamed(context, '/online');
        break;
      case GameMode.multiplayer:
        Navigator.pushNamed(context, '/multiplayer');
      case GameMode.multiple:
        Navigator.pushNamed(context, '/multiple');  
        break;
    }
  }
}

