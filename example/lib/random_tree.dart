import 'dart:math';

class RandomTree {
  static Map<int, List<int>> tree(int v, int maxperlevel, int startID) {
    Random rnd = Random();
    Map<int, List<int>> fanout = {};

    fanout[startID] = [];

    List<List<int>> nodesAtDepths = [[], []];

    int depth = v;
    int currentIndex = 0;
    int nodeID = startID + 1;

    nodesAtDepths[currentIndex].add(startID);

    while (depth > 1) {
      int nodesPerLevel = rnd.nextInt(maxperlevel) + 1;
      for (int i = 0; i < nodesPerLevel; i++) {
        int parent = nodesAtDepths[currentIndex]
            [rnd.nextInt(nodesAtDepths[currentIndex].length)];
        int children = nodeID++;

        List<int> siblings = fanout[parent]!;
        siblings.add(children);

        nodesAtDepths[1 - currentIndex].add(children);
        fanout[children] = [];
      }
      nodesAtDepths[currentIndex].clear();
      currentIndex = 1 - currentIndex;

      depth = depth - 1;
    }

    return fanout;
  }
}
