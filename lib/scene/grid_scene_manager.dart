import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/model_3d.dart';

class GridObject {
  final String modelPath;
  final String displayName;
  Model3D? model;
  final int gridX;
  final int gridZ;

  GridObject({
    required this.modelPath,
    required this.displayName,
    required this.gridX,
    required this.gridZ,
    this.model,
  });

  Vector3 get worldPosition => Vector3(gridX * 2.0, 0.0, gridZ * 2.0);

  Matrix4 get modelMatrix {
    return Matrix4.identity()..translateByVector3(worldPosition);
  }
}

class GridSceneManager extends ChangeNotifier {
  static const int gridSize = 10;
  final List<List<GridObject?>> _grid = List.generate(
    gridSize,
    (_) => List.filled(gridSize, null),
  );

  List<GridObject> get allObjects {
    final objects = <GridObject>[];
    for (var row in _grid) {
      for (var obj in row) {
        if (obj != null) objects.add(obj);
      }
    }
    return objects;
  }

  GridObject? getObjectAt(int x, int z) {
    if (x < 0 || x >= gridSize || z < 0 || z >= gridSize) return null;
    return _grid[x][z];
  }

  Future<void> addObject({
    required String modelPath,
    required String displayName,
    required int gridX,
    required int gridZ,
  }) async {
    if (gridX < 0 || gridX >= gridSize || gridZ < 0 || gridZ >= gridSize) {
      throw ArgumentError('Grid position out of bounds');
    }

    if (_grid[gridX][gridZ] != null) {
      throw StateError('Grid position already occupied');
    }

    final newObject = GridObject(
      modelPath: modelPath,
      displayName: displayName,
      gridX: gridX,
      gridZ: gridZ,
    );

    _grid[gridX][gridZ] = newObject;
    notifyListeners();

    try {
      final model = await Model3D.loadFromAsset(displayName, modelPath);
      _grid[gridX][gridZ] = GridObject(
        modelPath: modelPath,
        displayName: displayName,
        gridX: gridX,
        gridZ: gridZ,
        model: model,
      );
      notifyListeners();
    } catch (e) {
      _grid[gridX][gridZ] = null;
      notifyListeners();
      rethrow;
    }
  }

  void removeObject(int gridX, int gridZ) {
    if (gridX < 0 || gridX >= gridSize || gridZ < 0 || gridZ >= gridSize) {
      return;
    }
    _grid[gridX][gridZ] = null;
    notifyListeners();
  }

  void clearScene() {
    for (var i = 0; i < gridSize; i++) {
      for (var j = 0; j < gridSize; j++) {
        _grid[i][j] = null;
      }
    }
    notifyListeners();
  }

  void initializeWithPattern(List<List<String?>> pattern) {
    clearScene();

    for (var z = 0; z < pattern.length && z < gridSize; z++) {
      for (var x = 0; x < pattern[z].length && x < gridSize; x++) {
        final modelKey = pattern[z][x];
        if (modelKey != null) {
          final modelData = _modelLibrary[modelKey];
          if (modelData != null) {
            addObject(
              modelPath: modelData['path']!,
              displayName: modelData['name']!,
              gridX: x,
              gridZ: z,
            );
          }
        }
      }
    }
  }

  static const Map<String, Map<String, String>> _modelLibrary = {
    'grave': {'path': 'assets/graveyard/gravestone-flat.obj', 'name': 'Grave'},
    'cross': {'path': 'assets/graveyard/gravestone-cross.obj', 'name': 'Cross'},
    'tree': {'path': 'assets/graveyard/pine.obj', 'name': 'Tree'},
    'fence': {'path': 'assets/graveyard/fence.obj', 'name': 'Fence'},
    'zombie': {
      'path': 'assets/graveyard/character-zombie.obj',
      'name': 'Zombie',
    },
    'skeleton': {
      'path': 'assets/graveyard/character-skeleton.obj',
      'name': 'Skeleton',
    },
    'ghost': {'path': 'assets/graveyard/character-ghost.obj', 'name': 'Ghost'},
    'pumpkin': {
      'path': 'assets/graveyard/pumpkin-carved.obj',
      'name': 'Pumpkin',
    },
    'crypt': {'path': 'assets/graveyard/crypt-small.obj', 'name': 'Crypt'},
    'lantern': {
      'path': 'assets/graveyard/lantern-candle.obj',
      'name': 'Lantern',
    },
  };
}
