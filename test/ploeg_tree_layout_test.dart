import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:ploeg_tree_layout/ploeg_tree_layout.dart';

void main() {
  test('adds one to input values', () {
    Map<int, List<int>> simpleTree = {
      0: [1, 2],
      1: [3],
      2: [4, 5],
      3: [],
      4: [],
      5: []
    };

    Map<int, Offset> nodePositions = {};
    Map<int, Size> nodeSizes = {};
    expect(nodeSizes.length, 0);

    var algo = PloegTreeLayout(
        roots: () => [0],
        next: (v) => simpleTree[v]!,
        sizeGetter: (v) {
          Size size =
              Size(Random().nextInt(90) + 30, Random().nextInt(60) + 20);
          nodeSizes[v] = size;
          return size;
        },
        onPositionChange: (v, offset) => {nodePositions[v] = offset});
    var size = algo.layout().size;
    expect(size > Size.zero, true);
    expect(nodeSizes.length, 6);
  });

  test('big parent hides small child box', () {
    Map<int, List<int>> simpleTree = {
      0: [1],
      1: [],
    };

    Map<int, Offset> nodePositions = {};
    Map<int, Size> nodeSizes = const {0: Size(30, 30), 1: Size(10, 10)};

    var algo = PloegTreeLayout(
        roots: () => [0],
        next: (v) => simpleTree[v]!,
        sizeGetter: (v) => nodeSizes[v]!,
        onPositionChange: (v, offset) => {nodePositions[v] = offset},
        levelSeparation: 10);
    var box = algo.layout();
    expect(box.top, equals(0));
    expect(box.left, equals(-10));
    expect(box.size, equals(const Size(35, 50)));
  });

  test('big parent hides small child positions', () {
    Map<int, List<int>> simpleTree = {
      0: [1],
      1: [],
    };

    Map<int, Offset> nodePositions = {};
    Map<int, Size> nodeSizes = const {0: Size(30, 30), 1: Size(10, 10)};

    var algo = PloegTreeLayout(
        roots: () => [0],
        next: (v) => simpleTree[v]!,
        sizeGetter: (v) => nodeSizes[v]!,
        onPositionChange: (v, offset) => {nodePositions[v] = offset},
        levelSeparation: 10);
    algo.layout();

    expect(nodePositions[0], equals(const Offset(-10, 0)));
    expect(nodePositions[1], equals(const Offset(0, 40)));
  });
}
