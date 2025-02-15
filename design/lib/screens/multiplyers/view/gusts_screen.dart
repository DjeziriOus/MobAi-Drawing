import 'package:design/main.dart';
import 'package:design/screens/game/logic/game_cubit.dart';
import 'package:design/screens/game/logic/game_state.dart';
import 'package:design/utils/socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GustsScreen extends StatefulWidget {
  const GustsScreen({
    super.key,
    required this.channel,
    required this.streamSocket,
    required this.uid,
  });

  final WebSocketChannel channel;
  final StreamSocket streamSocket;
  final String uid;

  @override
  State<GustsScreen> createState() => _GustsScreenState();
}

class _GustsScreenState extends State<GustsScreen> {
  final TextEditingController _guessController = TextEditingController();
  final FocusNode _guessFocusNode = FocusNode();
  
  @override
  void dispose() {
    _guessController.dispose();
    _guessFocusNode.dispose();
    super.dispose();
  }

  void _submitGuess(BuildContext context) {
    if (_guessController.text.trim().isNotEmpty) {
      context.read<GameCubit>().sendGuess(_guessController.text.trim());
      _guessController.clear();
      _guessFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picture Guessing Game'),
        elevation: 0,
      ),
      body: BlocProvider(
        create: (context) => GameCubit(widget.channel, widget.streamSocket, widget.uid),
        child: BlocConsumer<GameCubit, GameState>(
          listener: (context, state) {
            if (state is WrongResponse) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('Incorrect guess - try again!'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GameState state) {
    if (state is GameReceivePic) {
      return Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(20.0),
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: SvgPicture.string(
                  state.svg_img,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _guessController,
                  focusNode: _guessFocusNode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelText: 'What do you see in the picture?',
                    hintText: 'Enter your guess here...',
                    prefixIcon: const Icon(Icons.lightbulb_outline),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _submitGuess(context),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submitGuess(context),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (state is PlayerWon) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.win ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 120,
              color: state.win ? Colors.amber : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              state.win ? 'Congratulations!' : 'Better luck next time!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: state.win ? Colors.amber : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              state.win ? 'You won the game!' : 'You lost this round',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const MyApp()));
              },
              icon: const Icon(Icons.replay),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (state is GameOver) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.games_outlined,
              size: 120,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Game Over',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thanks for playing!',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const MyApp()));
              },
              icon: const Icon(Icons.home),
              label: const Text('Return to Menu'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading game...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}