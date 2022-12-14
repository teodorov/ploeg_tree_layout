import 'dart:math';

import 'package:example/random_tree.dart';
import 'package:flutter/material.dart';
import 'package:ploeg_tree_layout/ploeg_tree_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GraphScene(),
    );
  }
}

class GraphScene extends StatefulWidget {
  const GraphScene({super.key});

  @override
  State<GraphScene> createState() => _GraphSceneState();
}

class _GraphSceneState extends State<GraphScene> {
  Map<int, List<int>> randomTree = RandomTree.tree(5, 2, 0);
  Map<int, List<int>> randomTree2 = RandomTree.tree(5, 3, 11);

  Map<int, Offset> nodePositions = {};
  Map<int, Size> nodeSizes = {};

  @override
  void initState() {
    super.initState();
    randomTree.addAll(randomTree2);

    var algo = PloegTreeLayout(
        roots: () => [0, 11],
        next: (v) => randomTree[v]!,
        sizeGetter: (v) {
          Size size =
              Size(Random().nextInt(90) + 30, Random().nextInt(60) + 20);
          nodeSizes[v] = size;
          return size;
        },
        onPositionChange: (v, offset) {
          nodePositions[v] = offset;
        });
    algo.layout();
  }

  final TransformationController _transformationController =
      TransformationController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(20.0),
        minScale: 0.0001,
        maxScale: 10.5,
        constrained: false,
        transformationController: _transformationController,
        child: SizedBox(
          height: 1000,
          width: 1000,
          child: ColoredBox(
            color: Colors.grey,
            child: Stack(
              children: <Widget>[
                CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: RelationPainter(
                      map: randomTree,
                      nodePositions: nodePositions,
                      nodeSizes: nodeSizes),
                ),
                ..._buildNodes()
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNodes() {
    final res = <Widget>[];
    nodePositions.forEach((node, offset) {
      res.add(NodeWidget(
        offset: offset,
        size: nodeSizes[node]!,
        node: node,
      ));
    });
    return res;
  }
}

class NodeWidget extends StatelessWidget {
  const NodeWidget(
      {super.key,
      required this.offset,
      required this.size,
      required this.node});
  final Offset offset;
  final Size size;
  final int node;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 1),
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Material(child: Text('$node'))),
      ),
    );
  }
}

class RelationPainter extends CustomPainter {
  RelationPainter(
      {required this.map,
      required this.nodePositions,
      required this.nodeSizes});

  final Map<int, List<int>> map;
  final Map<int, Offset> nodePositions;
  final Map<int, Size> nodeSizes;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodePositions.length > 1) {
      nodePositions.forEach((index, offset) {
        for (var t in map[index]!) {
          canvas.drawLine(
              Offset(offset.dx + nodeSizes[index]!.width / 2,
                  offset.dy + nodeSizes[index]!.height / 2),
              Offset(nodePositions[t]!.dx + nodeSizes[t]!.width / 2,
                  nodePositions[t]!.dy + nodeSizes[t]!.height / 2),
              Paint()
                ..color = Colors.black
                ..strokeWidth = 1);
        }
      });
    }
  }

  @override
  bool shouldRepaint(RelationPainter oldDelegate) => true;
}
