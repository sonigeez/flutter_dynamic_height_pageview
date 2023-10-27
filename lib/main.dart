import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap List Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

final List<GlobalKey> itemKeys = List.generate(20, (index) => GlobalKey());

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final List<GlobalKey> itemKeys = List.generate(20, (index) => GlobalKey());
  final List<double> itemOffsets = [];
  double totalHeight = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap List with Dynamic Heights'),
      ),
      body: ListView.builder(
        physics: SnapScrollPhysics(itemOffsets: itemOffsets),
        itemCount: 20,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              print('Item $index tapped');
            },
            child: MeasureSize(
              key: itemKeys[index],
              onSizeChanged: (size) {
                if (index >= itemOffsets.length) {
                  itemOffsets.add(totalHeight);
                  totalHeight += size.height;
                }
              },
              child: Container(
                height: (index % 3 == 0)
                    ? size.height * 0.5
                    : (index % 2 == 0)
                        ? size.height * 0.25
                        : size.height * 0.8,
                color: Colors.grey[(index % 10 + 1) * 100],
                child: Center(child: Text('Item $index')),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SnapScrollPhysics extends ScrollPhysics {
  final List<double> itemOffsets;

  const SnapScrollPhysics({required this.itemOffsets, ScrollPhysics? parent})
      : super(parent: parent);

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnapScrollPhysics(itemOffsets: itemOffsets, parent: parent);
  }

  double _getSnapTarget(double offset) {
    if (itemOffsets.isEmpty) return 0.0;

    final distances = itemOffsets.map((e) => (e - offset).abs()).toList();
    final minDistance = distances.reduce(min);
    final closestIndex = distances.indexOf(minDistance);

    return itemOffsets[closestIndex];
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final tolerance = toleranceFor(position);
    final targetPosition = _getSnapTarget(position.pixels);
    if (targetPosition != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        targetPosition,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}

typedef OnSizeChanged = void Function(Size size);

class MeasureSize extends StatefulWidget {
  final OnSizeChanged onSizeChanged;
  final Widget child;

  const MeasureSize({
    Key? key,
    required this.onSizeChanged,
    required this.child,
  }) : super(key: key);

  @override
  MeasureSizeState createState() => MeasureSizeState();
}

class MeasureSizeState extends State<MeasureSize> {
  Size? oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSize());

    return widget.child;
  }

  _checkSize() {
    final size = (context.findRenderObject() as RenderBox).size;

    if (oldSize != size) {
      widget.onSizeChanged(size);
    }

    oldSize = size;
  }
}
