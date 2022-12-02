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
    var size = algo.layout();
    expect(size > Size.zero, true);
    expect(nodeSizes.length, 6);
  });
}
