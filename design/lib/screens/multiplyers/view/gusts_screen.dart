import 'package:design/screens/game/logic/game_cubit.dart';
import 'package:design/screens/game/logic/game_state.dart';
import 'package:design/utils/socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GustsScreen extends StatefulWidget {
  const GustsScreen(
      {super.key,
      required this.channel,
      required this.streamSocket,
      required this.uid});
  final WebSocketChannel channel;
  final StreamSocket streamSocket;
  final String uid;

  @override
  State<GustsScreen> createState() => _GustsScreenState();
}

class _GustsScreenState extends State<GustsScreen> {
   String guess = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => GameCubit(widget.channel, widget.streamSocket, widget.uid),
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
               setState(() {
                  guess = value;
                  
               });
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              print(guess);
              context.read<GameCubit>().sendGuess(guess);
            },
            child: Text('Send'),
          ),
              ],
            );
          } else if (state is PlayerWon) {
            return Center(
              child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.win
            ? Icons.emoji_events
            : Icons.sentiment_dissatisfied,
              size: 100,
              color: state.win ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              state.win ? 'You won' : 'You lost',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: state.win ? Colors.green : Colors.red,
              ),
            ),
          ],
              ),
            );
          } else if (state is GameOver) {
            return Center(
              child: Text(
          'Game Over , You lose!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
              ),
            );
          } else {
            return const Center(
              child: Text('Wait .....'),
            );
          }
        }, listener: (BuildContext context, GameState state) {
          if (state is GameReceivePic) {
            
          } else if (state is WrongResponse) {
            print('Wrong response.............');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Try again!'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}
