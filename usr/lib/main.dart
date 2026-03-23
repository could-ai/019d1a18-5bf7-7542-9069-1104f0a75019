import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interactive Drawing App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // CRITICAL: Always explicitly set initialRoute and register it in routes
      initialRoute: '/',
      routes: {
        '/': (context) => const InteractiveScreen(),
      },
    );
  }
}

// Model to represent a single drawn line with its properties
class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double width;

  DrawnLine({required this.path, required this.color, required this.width});
}

class InteractiveScreen extends StatefulWidget {
  const InteractiveScreen({super.key});

  @override
  State<InteractiveScreen> createState() => _InteractiveScreenState();
}

class _InteractiveScreenState extends State<InteractiveScreen> {
  // State variables for our drawing board
  List<DrawnLine> lines = [];
  DrawnLine? currentLine;
  Color selectedColor = Colors.black;
  double strokeWidth = 5.0;

  // Available colors for the user to choose from
  final List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.pink,
  ];

  // Gesture Handlers
  void onPanStart(DragStartDetails details) {
    RenderBox? box = context.findRenderObject() as RenderBox?;
    Offset point = box?.globalToLocal(details.globalPosition) ?? details.globalPosition;
    
    // Adjust for the AppBar and Toolbar height to draw exactly under the finger/cursor
    point = Offset(point.dx, point.dy - Scaffold.of(context).appBarMaxHeight! - 60);

    setState(() {
      currentLine = DrawnLine(
        path: [details.localPosition],
        color: selectedColor,
        width: strokeWidth,
      );
    });
  }

  void onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentLine?.path.add(details.localPosition);
    });
  }

  void onPanEnd(DragEndDetails details) {
    setState(() {
      if (currentLine != null) {
        lines.add(currentLine!);
        currentLine = null;
      }
    });
  }

  void clearCanvas() {
    setState(() {
      lines.clear();
      currentLine = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Drawing Board'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: clearCanvas,
            tooltip: 'Clear Canvas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Interactive Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.grey[100],
            child: Row(
              children: [
                // Color Picker
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: colors.map((color) => GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: selectedColor == color ? 36 : 28,
                          height: selectedColor == color ? 36 : 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == color ? Colors.blueAccent : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (selectedColor == color)
                                const BoxShadow(
                                  color: Colors.black26, 
                                  blurRadius: 4, 
                                  spreadRadius: 1,
                                )
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                // Stroke Width Slider
                SizedBox(
                  width: 120,
                  child: Slider(
                    value: strokeWidth,
                    min: 1.0,
                    max: 20.0,
                    activeColor: selectedColor,
                    onChanged: (value) {
                      setState(() {
                        strokeWidth = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Interactive Canvas Area
          Expanded(
            child: GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                // CustomPaint handles the actual rendering of our lines
                child: CustomPaint(
                  painter: DrawingPainter(
                    lines: lines,
                    currentLine: currentLine,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CustomPainter to draw the lines on the canvas
class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final DrawnLine? currentLine;

  DrawingPainter({required this.lines, this.currentLine});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw all previously completed lines
    for (var line in lines) {
      paint.color = line.color;
      paint.strokeWidth = line.width;
      for (int i = 0; i < line.path.length - 1; i++) {
        canvas.drawLine(line.path[i], line.path[i + 1], paint);
      }
    }

    // Draw the line currently being drawn
    if (currentLine != null) {
      paint.color = currentLine!.color;
      paint.strokeWidth = currentLine!.width;
      for (int i = 0; i < currentLine!.path.length - 1; i++) {
        canvas.drawLine(currentLine!.path[i], currentLine!.path[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint when state changes
  }
}
