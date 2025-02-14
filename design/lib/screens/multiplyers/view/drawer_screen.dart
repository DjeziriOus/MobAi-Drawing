import 'dart:async';
import 'dart:convert';
import 'package:design/screens/game/logic/game_cubit.dart';
import 'package:design/utils/socket.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path_drawing/path_drawing.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key, required this.socket, required this.channel, required this.uid, });
  final StreamSocket socket;
  final WebSocketChannel channel;
  final String uid;
  

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  int _timeLeft = 45;
  late Timer _timer;
  List<Offset?> _points = [];
  String _currentPrompt = "Apple";

  late Timer _svgTimer;

  
  
  @override
  void initState() {
    super.initState();
    _startTimer();
    _startSVGStream();
  }

 

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer.cancel();
          // Handle time's up scenario
        }
      });
    });
  }

  void _startSVGStream() {
    _svgTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      String svgString = _convertToSVG();
      _sendSVG(svgString);
    });
  }

  String _convertToSVG() {
    // Create SVG header with viewBox based on canvas size
    final svgBuilder = StringBuffer();
    svgBuilder.write('''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300">
        <path d="
    ''');

    // Convert points to SVG path data
    String pathData = '';
    for (int i = 0; i < _points.length; i++) {
      if (_points[i] != null) {
        if (i == 0 || _points[i - 1] == null) {
          // Start new path
          pathData += 'M ${_points[i]!.dx} ${_points[i]!.dy} ';
        } else {
          // Continue path
          pathData += 'L ${_points[i]!.dx} ${_points[i]!.dy} ';
        }
      }
    }

    // Complete SVG with path attributes
    svgBuilder.write(pathData);
    svgBuilder.write('''" 
      stroke="black" 
      stroke-width="5" 
      stroke-linecap="round" 
      fill="none"/>
    </svg>''');

    return svgBuilder.toString();
  }

  void _sendSVG(String svgString) {
    try {
     
      final message = {
      'type':'send svg',
      'svg':svgString,
      'id':widget.uid
    };
    widget.channel.sink.add(jsonEncode(message));
    
    } catch (e) {
      print('Error sending SVG: $e');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _svgTimer.cancel();
   
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTimerDisplay(),
            _buildDrawingCanvas(),
            _buildPromptDisplay(),
          ],
        ),
      ),
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
            '${_timeLeft.toString().padLeft(2, '0')}',
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
        margin: const EdgeInsets.all(1),
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
          onPanUpdate: (details) {
            setState(() {
              RenderBox renderBox = context.findRenderObject() as RenderBox;
              Offset localPosition = renderBox.globalToLocal(details.globalPosition);

              if (localPosition.dx >= 0 &&
                  localPosition.dy >= 0 &&
                  localPosition.dx <= renderBox.size.width &&
                  localPosition.dy <= renderBox.size.height) {
                _points.add(localPosition);
              }
            });
          },
          onPanEnd: (details) => _points.add(null),
          child: CustomPaint(
            painter: DrawingPainter(points: _points),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _buildPromptDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: Colors.blue.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Text(
        'Draw: $_currentPrompt',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.center,
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