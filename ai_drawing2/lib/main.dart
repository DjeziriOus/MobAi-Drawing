import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// New imports for tflite_flutter and image processing.
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DrawingApp());
}

class DrawingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SketchScreen(),
    );
  }
}

class SketchScreen extends StatefulWidget {
  @override
  _SketchScreenState createState() => _SketchScreenState();
}

class _SketchScreenState extends State<SketchScreen> {
  List<Offset?> _points = [];
  GlobalKey _globalKey = GlobalKey();

  // Variables for inference
  String _inferenceResult = "";
  Timer? _debounceTimer;

  // tflite_flutter interpreter and labels list.
  Interpreter? _interpreter;
  List<String> _labels = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _interpreter?.close();
    super.dispose();
  }

  /// Load the TFLite model using tflite_flutter.
  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/quickdraw_model.tflite');
      print("Interpreter loaded successfully");

      print("Input shape: ${_interpreter!.getInputTensor(0).shape}");
      print("Input type: ${_interpreter!.getInputTensor(0).type}");
      print("Output shape: ${_interpreter!.getOutputTensor(0).shape}");
      print("Output type: ${_interpreter!.getOutputTensor(0).type}");
    } catch (e) {
      print("Error loading interpreter: $e");
    }
  }

  /// Load labels from assets/labels.txt.
  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/labels.txt');
      setState(() {
        // Split on new lines and remove any empty lines.
        _labels = labelsData
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      });
      print("Labels loaded: $_labels");
    } catch (e) {
      print("Error loading labels: $e");
    }
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
      _inferenceResult = "";
    });
  }

  Future<void> _saveDrawing() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = await getApplicationDocumentsDirectory();
    File imgFile = File('${directory.path}/drawing.png');
    await imgFile.writeAsBytes(pngBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Drawing saved to ${imgFile.path}")),
    );
  }

  /// Capture the canvas, preprocess the image, run inference, and update the result.
  Future<void> _runInference() async {
    if (_interpreter == null || _labels.isEmpty) {
      print("Interpreter or labels not loaded yet.");
      return;
    }
    try {
      // Capture the canvas image.
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image capturedImage = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData =
          await capturedImage.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Decode the image using the image package.
      img.Image? decodedImage = img.decodeImage(pngBytes);
      if (decodedImage == null) {
        print("Error decoding image");
        return;
      }

      // Resize the image to 28x28 (model's expected input size).
      img.Image resizedImage =
          img.copyResize(decodedImage, width: 28, height: 28);

      // Create a 4D tensor: [1, 28, 28, 1]
      final int imageSize = 28;
      var input = List.generate(
          1,
          (_) => List.generate(
              imageSize,
              (_) => List.generate(
                  imageSize, (_) => List.filled(1, 0.0, growable: false),
                  growable: false),
              growable: false),
          growable: false);

      // Fill the input tensor with grayscale values.
      // Convert each pixel to grayscale using a weighted sum.
      for (int y = 0; y < imageSize; y++) {
        for (int x = 0; x < imageSize; x++) {
          var pixel = resizedImage.getPixel(x, y);
          // Extract channels (values are expected between 0 and 255)
          double r = pixel.r / 255.0;
          double g = pixel.g / 255.0;
          double b = pixel.b / 255.0;
          double gray = 1.0 - (0.299 * r + 0.587 * g + 0.114 * b);

          input[0][y][x][0] = gray;
        }
      }

      // Prepare output buffer (model outputs shape [1, 100]).
      int numLabels = _labels.length; // Should be 100.
      var output = List.generate(1, (_) => List.filled(numLabels, 0.0));

      // Run inference.
      _interpreter!.run(input, output);

      // Find the index with the highest probability.
      List<double> probabilities = output[0].cast<double>();
      int maxIndex = 0;
      double maxProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      setState(() {
        _inferenceResult = _labels[maxIndex];
      });
    } catch (e) {
      print("Error running inference: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sketch Drawing"),
        actions: [
          IconButton(icon: Icon(Icons.delete), onPressed: _clearCanvas),
          IconButton(icon: Icon(Icons.save), onPressed: _saveDrawing),
        ],
      ),
      // Using a Stack to overlay the inference result on top of the drawing.
      body: Stack(
        children: [
          RepaintBoundary(
            key: _globalKey,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _points.add(details.localPosition);
                });
                // Debounce inference calls.
                if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                _debounceTimer =
                    Timer(Duration(milliseconds: 500), () => _runInference());
              },
              onPanEnd: (details) {
                _points.add(null);
              },
              child: CustomPaint(
                painter: SketchPainter(_points),
                size: Size.infinite,
              ),
            ),
          ),
          // Display the detection result at the bottom-left corner.
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(8.0),
              color: Colors.white70,
              child: Text(
                "Detection: $_inferenceResult",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class SketchPainter extends CustomPainter {
  final List<Offset?> points;

  SketchPainter(this.points);

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
  bool shouldRepaint(SketchPainter oldDelegate) => true;
}
