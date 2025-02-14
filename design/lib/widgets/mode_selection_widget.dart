import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/game_mode_cubit.dart';

class ModeSelectionWidget extends StatelessWidget {
  const ModeSelectionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildModeButton(
          context,
          'Offline Mode',
          Icons.person,
          GameMode.offline,
        ),
        const SizedBox(height: 20),
        _buildModeButton(
          context,
          'Online Mode',
          Icons.people,
          GameMode.online,
        ),
        const SizedBox(height: 20),
        _buildModeButton(
          context,
          'Multiplayer Room',
          Icons.groups,
          GameMode.multiplayer,
        ),
      ],
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    String title,
    IconData icon,
    GameMode mode,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue.shade700, backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      onPressed: () {
        context.read<GameModeCubit>().selectMode(mode);
        // TODO: Navigate to the respective game mode screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected mode: ${mode.toString()}')),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

