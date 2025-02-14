import 'package:flutter/material.dart';

class OnlineGameScreen extends StatelessWidget {
  const OnlineGameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Online Mode')),
      body: const Center(child: Text('Online Game Screen')),
    );
  }
}

