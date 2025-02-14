import 'package:design/screens/game/logic/game_cubit.dart';
import 'package:design/screens/game/logic/game_state.dart';
import 'package:design/utils/socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GustsScreen extends StatelessWidget {
  const GustsScreen(
      {super.key,
      required this.channel,
      required this.streamSocket,
      required this.uid});
  final WebSocketChannel channel;
  final StreamSocket streamSocket;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: BlocProvider(
        create: (context) => GameCubit(channel, streamSocket, uid),
        child: BlocConsumer<GameCubit, GameState>(builder: (context, state) {
          if (state is GameReceivePic) {
            return Column(
              children: [
              Expanded(
                child: SvgPicture.string(
                state.svg_img,
                ),
                ),
                Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Describe what you see',
                  ),
                  onChanged: (value) {
                  
                  },
                ),
                ),
                ElevatedButton(
                onPressed: () {
                  // Send the description
                  // sendDescription(description);
                },
                child: Text('Send'),
                ),
              ],
            );
          } else {
            return const Center(
              child: Text('Gusts screen'),
            );
          }
        }, listener: (BuildContext context, GameState state) {
          if (state is GameReceivePic) {}
        }),
      ),
    );
  }
}
