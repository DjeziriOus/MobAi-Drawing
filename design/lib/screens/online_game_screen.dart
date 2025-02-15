// online_game_screen.dart
import 'dart:async';
import 'package:design/screens/oneVsOne/logic/oneVsOne_cubit.dart';
import 'package:design/screens/oneVsOne/logic/oneVsOne_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

class OnlineGameScreen extends StatefulWidget {
  @override
  _OnlineGameScreenState createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  List<Offset?> points = [];
  Timer? _timer;
  String currentPrompt = "";
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (points.isNotEmpty) {
        String svgString = _convertToSVG();
        context.read<OnevsoneCubit>().sendSVG(svgString);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _convertToSVG() {
    if (points.isEmpty) return "";
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var point in points) {
      if (point != null) {
        minX = point.dx < minX ? point.dx : minX;
        minY = point.dy < minY ? point.dy : minY;
        maxX = point.dx > maxX ? point.dx : maxX;
        maxY = point.dy > maxY ? point.dy : maxY;
      }
    }

    String pathData = '';
    for (int i = 0; i < points.length; i++) {
      if (points[i] != null) {
        if (i == 0 || points[i - 1] == null) {
          pathData += 'M ${points[i]!.dx} ${points[i]!.dy} ';
        } else {
          pathData += 'L ${points[i]!.dx} ${points[i]!.dy} ';
        }
      }
    }

    return '''
      <svg viewBox="$minX $minY ${maxX - minX} ${maxY - minY}" xmlns="http://www.w3.org/2000/svg">
        <path d="$pathData" stroke="black" stroke-width="2" fill="none"/>
      </svg>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnevsoneCubit, OnevsoneState>(
      listener: (context, state) {
        if (state is OnevsOneStart) {
          setState(() {
            currentPrompt = state.prompt;
          });
          _showSnackBar(context, 'Draw: ${state.prompt}');
        } else if (state is OnevsOneWin) {
          _showGameResult(context, 'You Won!');
        } else if (state is OnevsOneLoss) {
          _showGameResult(context, 'You Lost!');
        } else if (state is DescriptionState) {
          print('Showing description: ${state.description}');
            _showSnackBar(
            context, 
            state.description,
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.purpleAccent.shade700,
            );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Drawing Game'),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Prompt: $currentPrompt', 
                  style: const TextStyle(fontSize: 18)
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      points.add(details.localPosition);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      points.add(details.localPosition);
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      points.add(null);
                    });
                  },
                  child: CustomPaint(
                    painter: DrawingPainter(points: points),
                    size: Size.infinite,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          points.clear();
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(
    BuildContext context, 
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showGameResult(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}


