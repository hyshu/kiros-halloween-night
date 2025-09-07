import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/model_3d.dart';
import '../core/tile_map.dart';
import '../core/tile_type.dart';
import '../core/position.dart';
import '../core/ghost_character.dart';
import '../core/enemy_manager.dart';
import '../core/enemy_character.dart';

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

  Vector3 get worldPosition => Vector3(gridX * Position.tileSpacing, 0.0, gridZ * Position.tileSpacing);

  Matrix4 get modelMatrix {
    return Matrix4.identity()..translateByVector3(worldPosition);
  }
}

class GridSceneManager extends ChangeNotifier {
  static const int gridSize = 10; // Keep for backward compatibility

  // For large world support
  TileMap? _tileMap;
  final Map<String, GridObject> _objects = {};

  // Character management
  GhostCharacter? _ghostCharacter;
  EnemyManager? _enemyManager;
  final Map<String, GridObject> _characterObjects = {};

  // Camera and viewport management for large world
  Vector3 _cameraTarget = Vector3(10, 0, 10);
  final double _viewportRadius = 50.0; // Only render objects within this radius

  // Constructor for large world
  GridSceneManager.withTileMap(this._tileMap) {
    if (_tileMap != null) {
      _updateCameraTarget();
    }
  }

  // Default constructor for backward compatibility
  GridSceneManager() : _tileMap = null;

  List<GridObject> get allObjects {
    final objects = <GridObject>[];

    if (_tileMap != null) {
      // For large world, return only objects within viewport
      objects.addAll(_getObjectsInViewport());
    } else {
      // Legacy behavior for small grid
      for (var obj in _objects.values) {
        objects.add(obj);
      }
    }

    // Add character objects (always visible)
    objects.addAll(_characterObjects.values);

    return objects;
  }

  List<GridObject> _getObjectsInViewport() {
    final viewportObjects = <GridObject>[];
    final cameraX = _cameraTarget.x / Position.tileSpacing; // Convert world to grid coordinates
    final cameraZ = _cameraTarget.z / Position.tileSpacing;
    final radius = _viewportRadius / Position.tileSpacing; // Convert to grid units

    for (final obj in _objects.values) {
      final dx = obj.gridX - cameraX;
      final dz = obj.gridZ - cameraZ;
      final distance = (dx * dx + dz * dz);

      if (distance <= radius * radius) {
        viewportObjects.add(obj);
      }
    }

    return viewportObjects;
  }

  GridObject? getObjectAt(int x, int z) {
    if (_tileMap != null) {
      return _objects['${x}_$z'];
    } else {
      // Legacy behavior - not used in large world
      return null;
    }
  }

  // Get the tile map for external access
  TileMap? get tileMap => _tileMap;

  // Get camera target for renderer
  Vector3 get cameraTarget => _cameraTarget;

  // Get the ghost character
  GhostCharacter? get ghostCharacter => _ghostCharacter;

  // Get the enemy manager
  EnemyManager? get enemyManager => _enemyManager;

  // Update camera target (for following player character later)
  void updateCameraTarget(Vector3 newTarget) {
    _cameraTarget = newTarget;
    // Reload objects around new camera position for large world
    if (_tileMap != null) {
      _loadObjectsAroundCamera();
    }
    notifyListeners();
  }

  /// Adds the ghost character to the scene
  Future<void> addGhostCharacter(GhostCharacter character) async {
    _ghostCharacter = character;

    // Create a GridObject for the character
    final characterObject = GridObject(
      modelPath: character.modelPath,
      displayName: character.id,
      gridX: character.position.x,
      gridZ: character.position.z,
    );

    _characterObjects[character.id] = characterObject;

    // Load the character's 3D model
    await character.loadModel();
    if (character.model != null) {
      _characterObjects[character.id] = GridObject(
        modelPath: character.modelPath,
        displayName: character.id,
        gridX: character.position.x,
        gridZ: character.position.z,
        model: character.model,
      );
    }

    // Update camera to follow the character
    _updateCameraToFollowCharacter();
    notifyListeners();
  }

  /// Updates the ghost character's position in the scene
  void updateGhostCharacterPosition() {
    if (_ghostCharacter == null) return;

    final character = _ghostCharacter!;
    final characterObject = GridObject(
      modelPath: character.modelPath,
      displayName: character.id,
      gridX: character.position.x,
      gridZ: character.position.z,
      model: character.model,
    );

    _characterObjects[character.id] = characterObject;

    // Update camera to follow the character
    _updateCameraToFollowCharacter();

    // Reload objects around new position for large world
    if (_tileMap != null) {
      _loadObjectsAroundCamera();
    }

    notifyListeners();
  }

  /// Updates camera to follow the ghost character
  void _updateCameraToFollowCharacter() {
    if (_ghostCharacter != null) {
      final pos = _ghostCharacter!.position;
      _cameraTarget = Vector3(pos.x * Position.tileSpacing, 0.0, pos.z * Position.tileSpacing);

      // Update enemy activation based on new player position
      if (_enemyManager != null) {
        _enemyManager!.updateEnemyActivation(pos);
      }
    }
  }

  /// Spawns enemies across the world map
  Future<void> spawnEnemies({
    double spawnDensity = 0.8,
    Position? playerSpawn,
  }) async {
    if (_enemyManager == null) {
      throw StateError('Enemy manager not initialized');
    }

    // Spawn enemies using the enemy manager
    await _enemyManager!.spawnEnemies(
      spawnDensity: spawnDensity,
      playerSpawn: playerSpawn,
    );

    // Add enemy objects to the scene for rendering
    await _addEnemyObjectsToScene();

    notifyListeners();
  }

  /// Adds enemy objects to the scene for rendering
  Future<void> _addEnemyObjectsToScene() async {
    if (_enemyManager == null) return;

    for (final enemy in _enemyManager!.enemies.values) {
      await _addEnemyToScene(enemy);
    }
  }

  /// Adds a single enemy to the scene
  Future<void> _addEnemyToScene(EnemyCharacter enemy) async {
    final enemyObject = GridObject(
      modelPath: enemy.modelPath,
      displayName: enemy.id,
      gridX: enemy.position.x,
      gridZ: enemy.position.z,
      model: enemy.model,
    );

    _characterObjects[enemy.id] = enemyObject;
  }

  /// Updates enemy positions in the scene (for when enemies move)
  void updateEnemyPositions() {
    if (_enemyManager == null) return;

    for (final enemy in _enemyManager!.enemies.values) {
      final enemyObject = GridObject(
        modelPath: enemy.modelPath,
        displayName: enemy.id,
        gridX: enemy.position.x,
        gridZ: enemy.position.z,
        model: enemy.model,
      );

      _characterObjects[enemy.id] = enemyObject;
    }

    notifyListeners();
  }

  /// Removes an enemy from the scene
  void removeEnemyFromScene(String enemyId) {
    _characterObjects.remove(enemyId);
    notifyListeners();
  }

  void _updateCameraTarget() {
    if (_tileMap?.playerSpawn != null) {
      final spawn = _tileMap!.playerSpawn!;
      _cameraTarget = Vector3(spawn.x * Position.tileSpacing, 0.0, spawn.z * Position.tileSpacing);
    }
  }

  Future<void> addObject({
    required String modelPath,
    required String displayName,
    required int gridX,
    required int gridZ,
  }) async {
    if (_tileMap != null) {
      // For large world, check bounds against tile map
      if (!_tileMap!.isValidPosition(Position(gridX, gridZ))) {
        throw ArgumentError('Grid position out of bounds');
      }
    } else {
      // Legacy bounds checking
      if (gridX < 0 || gridX >= gridSize || gridZ < 0 || gridZ >= gridSize) {
        throw ArgumentError('Grid position out of bounds');
      }
    }

    final key = '${gridX}_$gridZ';
    if (_objects.containsKey(key)) {
      // For large world, silently skip occupied positions instead of throwing
      if (_tileMap != null) {
        return;
      }
      throw StateError('Grid position already occupied');
    }

    final newObject = GridObject(
      modelPath: modelPath,
      displayName: displayName,
      gridX: gridX,
      gridZ: gridZ,
    );

    _objects[key] = newObject;
    notifyListeners();

    try {
      final model = await Model3D.loadFromAsset(displayName, modelPath);
      _objects[key] = GridObject(
        modelPath: modelPath,
        displayName: displayName,
        gridX: gridX,
        gridZ: gridZ,
        model: model,
      );
      notifyListeners();
    } catch (e) {
      _objects.remove(key);
      notifyListeners();
      rethrow;
    }
  }

  void removeObject(int gridX, int gridZ) {
    final key = '${gridX}_$gridZ';
    _objects.remove(key);
    notifyListeners();
  }

  void clearScene() {
    _objects.clear();
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

  /// Initialize the scene with a large TileMap
  Future<void> initializeWithTileMap(TileMap tileMap) async {
    clearScene();
    _tileMap = tileMap;

    // Initialize enemy manager
    _enemyManager = EnemyManager();
    _enemyManager!.initialize(tileMap);

    // Load objects in viewport around camera target
    await _loadObjectsAroundCamera();

    _updateCameraTarget();
    notifyListeners();
  }

  /// Load objects in the viewport around the current camera target
  Future<void> _loadObjectsAroundCamera() async {
    if (_tileMap == null) return;

    final cameraX = (_cameraTarget.x / Position.tileSpacing).round();
    final cameraZ = (_cameraTarget.z / Position.tileSpacing).round();
    final radius = (_viewportRadius / Position.tileSpacing).round();

    final objectsToPlace = <Future<void>>[];

    // Load all tiles in the viewport area
    for (int dz = -radius; dz <= radius; dz++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final x = cameraX + dx;
        final z = cameraZ + dz;
        final position = Position(x, z);

        if (!_tileMap!.isValidPosition(position)) continue;

        final key = '${x}_$z';
        if (_objects.containsKey(key)) continue; // Already loaded

        final tileType = _tileMap!.getTileAt(position);
        final modelKey = _getTileModelKey(tileType, position);

        if (modelKey != null) {
          final modelData = _modelLibrary[modelKey];
          if (modelData != null) {
            objectsToPlace.add(
              addObject(
                modelPath: modelData['path']!,
                displayName: modelData['name']!,
                gridX: x,
                gridZ: z,
              ),
            );
          }
        }
      }
    }

    // Execute all object placements
    await Future.wait(objectsToPlace);
  }

  /// Get the appropriate model key for a tile type and position
  String? _getTileModelKey(TileType tileType, Position position) {
    switch (tileType) {
      case TileType.wall:
        return _getSmartWallModel(position);
      case TileType.obstacle:
        return _getSmartObstacleModel(position);
      case TileType.candy:
        // Always show candy items
        final variant = (position.x * 5 + position.z * 13) % 3;
        switch (variant) {
          case 0:
            return 'candy_apple';
          case 1:
            return 'candy_chocolate';
          case 2:
            return 'candy_lollipop';
          default:
            return 'candy_apple';
        }
      case TileType.floor:
        // Show decorative items more frequently to visualize pathways
        if ((position.x * 11 + position.z * 17) % 20 == 0) {
          return 'lantern';
        }
        return null; // Most floor tiles remain empty for navigation
    }
  }

  /// Get smart wall model based on neighboring tiles
  String _getSmartWallModel(Position position) {
    if (_tileMap == null) {
      // Fallback to old behavior if no tile map
      final variant = (position.x + position.z) % 3;
      switch (variant) {
        case 0:
          return 'fence';
        case 1:
          return 'grave';
        case 2:
          return 'tree';
        default:
          return 'fence';
      }
    }

    // Check adjacent tiles (up, down, left, right)
    final up = Position(position.x, position.z - 1);
    final down = Position(position.x, position.z + 1);
    final left = Position(position.x - 1, position.z);
    final right = Position(position.x + 1, position.z);

    final upTile = _tileMap!.getTileAt(up);
    final downTile = _tileMap!.getTileAt(down);
    final leftTile = _tileMap!.getTileAt(left);
    final rightTile = _tileMap!.getTileAt(right);

    // If any adjacent tile is not a wall, use brick-wall
    if (upTile != TileType.wall ||
        downTile != TileType.wall ||
        leftTile != TileType.wall ||
        rightTile != TileType.wall) {
      return 'brick-wall';
    }

    // Check diagonal neighbors (top-right, top-left, bottom-right, bottom-left)
    final topRight = Position(position.x + 1, position.z - 1);
    final topLeft = Position(position.x - 1, position.z - 1);
    final bottomRight = Position(position.x + 1, position.z + 1);
    final bottomLeft = Position(position.x - 1, position.z + 1);

    final topRightTile = _tileMap!.getTileAt(topRight);
    final topLeftTile = _tileMap!.getTileAt(topLeft);
    final bottomRightTile = _tileMap!.getTileAt(bottomRight);
    final bottomLeftTile = _tileMap!.getTileAt(bottomLeft);

    // If all adjacent are walls but any diagonal is not wall, use brick-wall-curve-small
    if (topRightTile != TileType.wall ||
        topLeftTile != TileType.wall ||
        bottomRightTile != TileType.wall ||
        bottomLeftTile != TileType.wall) {
      return 'brick-wall-curve-small';
    }

    // Default to gravestone-bevel if completely surrounded by walls
    return 'gravestone-bevel';
  }

  /// Get smart obstacle model based on neighboring tiles
  String _getSmartObstacleModel(Position position) {
    if (_tileMap == null) {
      // Fallback to old behavior if no tile map
      final variant = (position.x * 3 + position.z * 7) % 4;
      switch (variant) {
        case 0:
          return 'crypt';
        case 1:
          return 'grave';
        case 2:
          return 'tree';
        case 3:
          return 'pumpkin';
        default:
          return 'crypt';
      }
    }

    // Check adjacent tiles (up, down, left, right)
    final up = Position(position.x, position.z - 1);
    final down = Position(position.x, position.z + 1);
    final left = Position(position.x - 1, position.z);
    final right = Position(position.x + 1, position.z);

    final upTile = _tileMap!.getTileAt(up);
    final downTile = _tileMap!.getTileAt(down);
    final leftTile = _tileMap!.getTileAt(left);
    final rightTile = _tileMap!.getTileAt(right);

    // If any adjacent tile is not a wall, use brick-wall
    if (upTile != TileType.wall ||
        downTile != TileType.wall ||
        leftTile != TileType.wall ||
        rightTile != TileType.wall) {
      return 'brick-wall';
    }

    // Check diagonal neighbors (top-right, top-left, bottom-right, bottom-left)
    final topRight = Position(position.x + 1, position.z - 1);
    final topLeft = Position(position.x - 1, position.z - 1);
    final bottomRight = Position(position.x + 1, position.z + 1);
    final bottomLeft = Position(position.x - 1, position.z + 1);

    final topRightTile = _tileMap!.getTileAt(topRight);
    final topLeftTile = _tileMap!.getTileAt(topLeft);
    final bottomRightTile = _tileMap!.getTileAt(bottomRight);
    final bottomLeftTile = _tileMap!.getTileAt(bottomLeft);

    // If all adjacent are walls but any diagonal is not wall, use brick-wall-curve-small
    if (topRightTile != TileType.wall ||
        topLeftTile != TileType.wall ||
        bottomRightTile != TileType.wall ||
        bottomLeftTile != TileType.wall) {
      return 'brick-wall-curve-small';
    }

    // Default to gravestone-bevel if completely surrounded by walls
    return 'gravestone-bevel';
  }

  static const Map<String, Map<String, String>> _modelLibrary = {
    // Walls and barriers
    'grave': {'path': 'assets/graveyard/gravestone-flat.obj', 'name': 'Grave'},
    'cross': {'path': 'assets/graveyard/gravestone-cross.obj', 'name': 'Cross'},
    'tree': {'path': 'assets/graveyard/pine.obj', 'name': 'Tree'},
    'fence': {'path': 'assets/graveyard/fence.obj', 'name': 'Fence'},
    'brick-wall': {
      'path': 'assets/graveyard/brick-wall.obj',
      'name': 'Brick Wall',
    },
    'brick-wall-curve-small': {
      'path': 'assets/graveyard/brick-wall-curve-small.obj',
      'name': 'Brick Wall Curve Small',
    },
    'gravestone-bevel': {
      'path': 'assets/graveyard/gravestone-bevel.obj',
      'name': 'Gravestone Bevel',
    },

    // Obstacles and structures
    'crypt': {'path': 'assets/graveyard/crypt-small.obj', 'name': 'Crypt'},
    'pumpkin': {
      'path': 'assets/graveyard/pumpkin-carved.obj',
      'name': 'Pumpkin',
    },

    // Characters
    'zombie': {
      'path': 'assets/graveyard/character-zombie.obj',
      'name': 'Zombie',
    },
    'skeleton': {
      'path': 'assets/graveyard/character-skeleton.obj',
      'name': 'Skeleton',
    },
    'ghost': {'path': 'assets/graveyard/character-ghost.obj', 'name': 'Ghost'},
    'vampire': {
      'path': 'assets/graveyard/character-vampire.obj',
      'name': 'Vampire',
    },

    // Human characters (using character assets)
    'human_male_a': {
      'path': 'assets/characters/character-male-a.obj',
      'name': 'Human Male A',
    },
    'human_male_b': {
      'path': 'assets/characters/character-male-b.obj',
      'name': 'Human Male B',
    },
    'human_male_c': {
      'path': 'assets/characters/character-male-c.obj',
      'name': 'Human Male C',
    },
    'human_female_a': {
      'path': 'assets/characters/character-female-a.obj',
      'name': 'Human Female A',
    },
    'human_female_b': {
      'path': 'assets/characters/character-female-b.obj',
      'name': 'Human Female B',
    },
    'human_female_c': {
      'path': 'assets/characters/character-female-c.obj',
      'name': 'Human Female C',
    },

    // Decorative items
    'lantern': {
      'path': 'assets/graveyard/lantern-candle.obj',
      'name': 'Lantern',
    },

    // Candy items using food models
    'candy_apple': {'path': 'assets/foods/apple.obj', 'name': 'Candy Apple'},
    'candy_chocolate': {
      'path': 'assets/foods/chocolate.obj',
      'name': 'Chocolate',
    },
    'candy_lollipop': {'path': 'assets/foods/lollypop.obj', 'name': 'Lollipop'},
    'candy_cookie': {'path': 'assets/foods/cookie.obj', 'name': 'Cookie'},
    'candy_donut': {'path': 'assets/foods/donut.obj', 'name': 'Donut'},
    'candy_cupcake': {'path': 'assets/foods/cupcake.obj', 'name': 'Cupcake'},
  };
}
