library ploeg_tree_layout;

import 'dart:math';
import 'dart:ui';

///
///Ported from Java by Ciprian TEODOROV on 21/02/17.
///https://bitbucket.org/plug-team/plug-utils-fx/src/master/src/plug/utils/ui/graph/layout/PloegTreeLayout.java
///date: 25/11/2022
/// This layout is an adaptation of the extended Reingold-Tilford algorithm as described in the paper
/// "Drawing Non-layered Tidy Trees in Linear Time" by Atze van der Ploeg
/// Accepted for publication in Software: Practice and Experience, to Appear.
///
/// The original implementation can be found at:
/// @see <a href="https://github.com/cwi-swat/non-layered-tidy-trees">non-layered-tidy-trees</a>
///
/// This code is in the public domain, use it any way you wish. A reference to the paper is
/// appreciated!

class PloegTreeLayout<V> {
  PloegTreeLayout({
    required this.roots,
    required this.next,
    required this.sizeGetter,
    required this.onPositionChange,
    this.levelSeparation = 20.0,
    this.siblingSeparation = 5.0,
  })  : assert(siblingSeparation >= 0),
        assert(levelSeparation >= 0);

  /// A function returning the list of tree roots
  List<V> Function() roots;

  /// A function returning the children of a node in a tree
  List<V> Function(V) next;

  /// A function returning the size (width, height) of a node
  Size Function(V) sizeGetter;

  /// The separation between the levels in the layout
  double levelSeparation;

  /// The minimum distance between two siblings
  double siblingSeparation;

  /// A callback which is invoked when the position of a node is known
  Function(V, Offset) onPositionChange;

  final Map<V?, _LayoutData<V>> _layoutDataMap = Map.identity();

  ///The entry point for the layout algorithm
  Size layout() {
    firstWalk(null, -(levelSeparation));
    return secondWalk(null, 0);
  }

  void firstWalk(V? node, double yPosition) {
    Size nodeSize = node == null ? const Size(0, 0) : sizeGetter(node);
    _layoutDataMap.putIfAbsent(
        node,
        () => _LayoutData(Offset(double.infinity, yPosition),
            Size(nodeSize.width + siblingSeparation, nodeSize.height)));

    List<V> children = getChildren(node);
    if (children.isEmpty) {
      setExtremes(node);
      return;
    }
    V leftmostChild = children[0];
    //children of node are at node.y + node.height
    double childrenY = yPosition + height(node) + levelSeparation;
    firstWalk(leftmostChild, childrenY);
    //Create siblings in contour minimal vertical coordinate and index list
    IYL ih = updateIYL(bottom(extremeLeft(leftmostChild)), 0, null);

    for (int i = 1; i < children.length; i++) {
      V ithChild = children[i];
      firstWalk(ithChild, childrenY);
      //Store lowest vertical coordinate while extreme nodes still point in current subtree.
      double minY = bottom(extremeRight(ithChild));
      seperate(node, i, ih);
      ih = updateIYL(minY, i, ih);
    }
    positionRoot(node);
    setExtremes(node);
  }

  Size secondWalk(V? node, double modsum, [Size boxSize = Size.zero]) {
    List<V> children = getChildren(node);
    _LayoutData<V> nodeData = _layoutDataMap[node]!;
    modsum += nodeData.mod;
    // Set absolute (non-relative) horizontal coordinate.
    nodeData.position = Offset(nodeData.prelim + modsum, nodeData.position.dy);
    if (node != null) {
      onPositionChange(node, nodeData.position);
      boxSize = boxSize.union(Size(nodeData.position.dx + nodeData.size.width,
          nodeData.position.dy + nodeData.size.height));
    }
    addChildSpacing(node);
    for (int i = 0; i < children.length; i++) {
      var childBox = secondWalk(children[i], modsum, boxSize);
      boxSize = boxSize.union(childBox);
    }
    return boxSize;
  }

  // Process change and shift to add intermediate spacing to mod.
  void addChildSpacing(V? node) {
    List<V> children = getChildren(node);
    double d = 0, modsumdelta = 0;
    for (int i = 0; i < children.length; i++) {
      _LayoutData ithData = _layoutDataMap[children[i]]!;
      d += ithData.shift;
      modsumdelta += d + ithData.change;
      ithData.mod += modsumdelta;
    }
  }

  List<V> getChildren(V? node) {
    if (node == null) {
      return roots();
    }
    return next(node);
  }

  IYL updateIYL(double minY, int i, IYL? ih) {
    //Remove siblings that are hidden by the new subtree.
    while (ih != null && minY >= ih.lowY) {
      ih = ih.nxt;
    }
    // Prepend the new subtree.
    return IYL(minY, i, ih);
  }

  void positionRoot(V? node) {
    List<V> children = getChildren(node);
    // Position root between children, taking into account their mod.
    V leftmostChild = children[0];
    V rightmostChild = children[children.length - 1];
    setPrelim(
        node,
        (prelim(leftmostChild) +
                    mod(leftmostChild) +
                    prelim(rightmostChild) +
                    mod(rightmostChild) +
                    width(rightmostChild)) /
                2 -
            width(node) / 2);
  }

  void setExtremes(V? node) {
    List<V> children = getChildren(node);
    var data = _layoutDataMap[node]!;
    if (children.isEmpty) {
      //if this node is a leaf its extremes are itself
      data.extremeLeft = node;
      data.extremeRight = node;
      data.msel = data.mser = 0;
      return;
    }
    //the extreme left is the extreme left of its leftmost child
    V leftmostChild = children[0];
    data.extremeLeft = extremeLeft(leftmostChild);
    data.msel = msel(leftmostChild);
    //the extreme right is the extreme right of its rightmost child
    V rightmostChild = children[children.length - 1];
    data.extremeRight = extremeRight(rightmostChild);
    data.msel = mser(rightmostChild);
  }

  void seperate(V? node, int i, IYL? ih) {
    List<V> children = getChildren(node);
    //Right contour node of left siblings and its sum of modfiers.
    V? sr = children[i - 1];
    assert(sr != null);
    double mssr = sr != null ? mod(sr) : 0;
    //Left contour node of current subtree and its sum of modfiers.
    V? cl = children[i];
    double mscl = cl != null ? mod(cl) : 0;
    while (sr != null && cl != null) {
      if (ih != null && bottom(sr) > ih.lowY) ih = ih.nxt;
      //How far to the left of the right side of sr is the left side of cl?
      double dist = (mssr + prelim(sr) + width(sr)) - (mscl + prelim(cl));
      if (dist > 0 && ih != null) {
        mscl += dist;
        moveSubtree(node, i, ih.index, dist);
      }
      double sy = bottom(sr), cy = bottom(cl);
      //Advance highest node(s) and sum(s) of modifiers
      if (sy <= cy) {
        sr = nextRightContour(sr, getChildren(sr));
        if (sr != null) mssr += mod(sr);
      }
      if (sy >= cy) {
        cl = nextLeftContour(cl, getChildren(cl));
        if (cl != null) mscl += mod(cl);
      }
    }
    // Set threads and update extreme nodes.
    // In the first case, the current subtree must be taller than the left siblings.
    if (sr == null && cl != null) {
      setLeftThread(node, i, cl, mscl);
    }
    // In this case, the left siblings must be taller than the current subtree.
    else if (sr != null && cl == null) {
      setRightThread(node, i, sr, mssr);
    }
  }

  void moveSubtree(V? node, int i, int si, double dist) {
    List<V> children = getChildren(node);
    //Move subtree by changing mod.
    _LayoutData<V> data = _layoutDataMap[children[i]]!;
    data.mod += dist;
    data.msel += dist;
    data.mser += dist;
    distributeExtra(node, i, si, dist);
  }

  double bottom(V node) => getY(node) + height(node);

  double getY(V node) => _layoutDataMap[node]!.position.dy;

  double width(node) => _layoutDataMap[node]!.size.width;

  double height(node) => _layoutDataMap[node]!.size.height;

  extremeLeft(V node) => _layoutDataMap[node]!.extremeLeft;
  extremeRight(V node) => _layoutDataMap[node]!.extremeLeft;
  leftThread(V node) => _layoutDataMap[node]!.leftThread;

  void setLeftThread(V? node, int i, V cl, double modsumcl) {
    List<V> children = getChildren(node);
    _LayoutData<V> leftmostData = _layoutDataMap[children[0]]!;
    _LayoutData<V> ithData = _layoutDataMap[children[i]]!;
    _LayoutData<V> clData = _layoutDataMap[cl]!;
    _LayoutData<V> liData = _layoutDataMap[leftmostData.extremeLeft]!;

    liData.leftThread = cl;
    // Change mod so that the sum of modifier after following thread is correct.
    double diff = (modsumcl - clData.mod) - leftmostData.msel;
    liData.mod += diff;
    // Change preliminary x coordinate so that the node does not move.
    liData.prelim -= diff;
    // Update extreme node and its sum of modifiers.
    leftmostData.extremeLeft = ithData.extremeLeft;
    leftmostData.msel = ithData.msel;
  }

  void distributeExtra(V? node, int i, int si, double dist) {
    //Are there intermediate children?
    if (si == i - 1) {
      return;
    }
    List<V> children = getChildren(node);
    int nr = i - si;
    _LayoutData<V> si1Data = _layoutDataMap[children[si + 1]]!;
    si1Data.shift += dist / nr;
    _LayoutData<V> ithData = _layoutDataMap[children[i]]!;
    ithData.shift -= dist / nr;
    ithData.change -= dist - dist / nr;
  }

  rightThread(V node) => _layoutDataMap[node]!.rightThread;
  //Symmetrical to setLeftThread.
  void setRightThread(V? node, int i, V sr, double modsumsr) {
    List<V> children = getChildren(node);

    _LayoutData<V> beforeIData = _layoutDataMap[children[i - 1]]!;
    _LayoutData<V> ithData = _layoutDataMap[children[i]]!;
    _LayoutData<V> srData = _layoutDataMap[sr]!;
    _LayoutData<V> riData = _layoutDataMap[ithData.extremeRight]!;
    riData.rightThread = sr;

    double diff = (modsumsr - srData.mod) - ithData.mser;
    riData.mod += diff;
    riData.prelim -= diff;
    ithData.extremeRight = beforeIData.extremeRight;
    ithData.mser = beforeIData.mser;
  }

  prelim(V node) => _layoutDataMap[node]!.prelim;
  setPrelim(V? node, double value) => _layoutDataMap[node]!.prelim = value;
  mod(V node) => _layoutDataMap[node]!.mod;
  msel(V node) => _layoutDataMap[node]!.msel;
  mser(V node) => _layoutDataMap[node]!.mser;

  nextLeftContour(V node, List<V> children) =>
      children.isEmpty ? leftThread(node) : children[0];

  nextRightContour(V node, List<V> children) =>
      children.isEmpty ? rightThread(node) : children[children.length - 1];
}

class _LayoutData<V> {
  _LayoutData(this.position, this.size);

  ///The position that will be computed
  Offset position;

  ///The size of the node
  Size size;

  ///modifier, to store for each node how much its entire subtree should be moved horizontally.
  ///Moving a subtree is then done by simply updating this modifier.
  double mod = 0;

  ///used to remember the *preliminary* horizontal coordinate of the node.
  ///This is set when we position the root
  /// after moving its children and
  /// represents the distance that the left side of the root
  /// is positioned relative to the left side of its first child
  double prelim = 0;

  ///To move an arbitrary number of intermediate siblings in O(1)
  /// Buchheim et al. [12] propose to add two fields to each node, namely *shift* and *change*
  double shift = 0;
  double change = 0;

  /// left and right thread
  V? leftThread, rightThread;

  /// the extreme left and right nodes
  V? extremeLeft, extremeRight;

  ///sum of modifiers at the extreme nodes
  /// msel: modifier sum extreme left
  /// mser: modifier sum extreme right
  double msel = 0, mser = 0;
}

//A linked list of the indexes of left siblings and their lowest vertical coordinate.
class IYL {
  IYL(this.lowY, this.index, this.nxt);
  double lowY;
  int index;
  IYL? nxt;
}

extension Union on Size {
  union(Size other) {
    return Size(max(width, other.width), max(height, other.height));
  }
}
