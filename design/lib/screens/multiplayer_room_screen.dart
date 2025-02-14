import 'package:flutter/material.dart';
import 'dart:math';

class MultiplayerRoomScreen extends StatefulWidget {
  const MultiplayerRoomScreen({Key? key}) : super(key: key);

  @override
  _MultiplayerRoomScreenState createState() => _MultiplayerRoomScreenState();
}

class _MultiplayerRoomScreenState extends State<MultiplayerRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _currentScreen = 'selection';
  List<String> _players = [];
  bool _isDrawer = false;
  String _currentPrompt = '';
  List<Offset?> _points = [];
  int _timeLeft = 60;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _createRoom() {
    setState(() {
      _currentScreen = 'waiting';
      _players = ['You (Host)', 'AI Player 1', 'AI Player 2'];
    });
  }

  void _joinRoom() {
    if (_codeController.text.isNotEmpty) {
      setState(() {
        _currentScreen = 'waiting';
        _players = ['You', 'AI Host', 'AI Player 1', 'AI Player 2'];
      });
    }
  }

  void _startGame() {
    setState(() {
      _currentScreen = 'game';
      _isDrawer = Random().nextBool();
      _currentPrompt = _isDrawer ? 'Draw a cat' : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: _buildCurrentScreen(),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentScreen) {
      case 'waiting':
        return 'Waiting Room';
      case 'game':
        return 'Multiplayer Game';
      default:
        return 'Multiplayer Room';
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 'waiting':
        return _buildWaitingRoom();
      case 'game':
        return _buildGameScreen();
      default:
        return _buildRoomSelection();
    }
  }

  Widget _buildRoomSelection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _createRoom,
            child: const Text('Create Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Enter Room Code',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _joinRoom,
            child: const Text('Join Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWaitingRoom() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _players.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text(_players[index][0]),
                ),
                title: Text(_players[index]),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Start Game?'),
                    content: const Text('Are all players ready to start?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startGame();
                        },
                        child: const Text('Start'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('Start Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        _buildTimerDisplay(),
        _buildDrawingCanvas(),
        if (!_isDrawer) _buildGuessInput(),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, size: 24, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '$_timeLeft',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: GestureDetector(
          onPanUpdate: _isDrawer ? (details) {
            setState(() {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              _points.add(renderBox.globalToLocal(details.globalPosition));
            });
          } : null,
          onPanEnd: _isDrawer ? (details) => _points.add(null) : null,
          child: CustomPaint(
            painter: DrawingPainter(points: _points),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _buildGuessInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Enter your guess',
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              // TODO: Implement guess submission logic
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}



class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}