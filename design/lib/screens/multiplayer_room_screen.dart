import 'package:flutter/material.dart';

class MultiplayerRoomScreen extends StatelessWidget {
  const MultiplayerRoomScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multiplayer Room')),
      body: const Center(child: Text('Multiplayer Room Screen')),
    );
  }
}

