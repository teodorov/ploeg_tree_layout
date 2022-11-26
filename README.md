# Ploeg Tree Layout

This layout is the Ploeg adaptation of the extended Reingold-Tilford algorithm as described in the paper
van der Ploeg, A. (2014), Drawing non-layered tidy trees in linear time, Softw. Pract. Exper., 44, pages 1467– 1484, doi: 10.1002/spe.2213

The original implementation can be found on github at:
[non-layered-tidy-trees](https://github.com/cwi-swat/non-layered-tidy-trees)

This code is in the public domain, use it any way you wish. A reference to the paper is appreciated!

## Features

This implementation isolates the algorithm from the tree datastructure. The tree is obtained through via

```dart
  List<V> Function() roots;
  List<V> Function(V) next;
```

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
