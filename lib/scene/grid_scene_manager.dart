import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/model_3d.dart';
import '../core/tile_map.dart';
import '../core/tile_type.dart';
import '../core/position.dart';
import '../core/ghost_character.dart';

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
  static const int gridSize = 10; // Keep for backward compatibility
  
  // For large world support
  TileMap? _tileMap;
  final Map<String, GridObject> _objects = {};
  
  // Character management
  GhostCharacter? _ghostCharacter;
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
    final cameraX = _cameraTarget.x / 2.0; // Convert world to grid coordinates
    final cameraZ = _cameraTarget.z / 2.0;
    final radius = _viewportRadius / 2.0; // Convert to grid units
    
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
      _cameraTarget = Vector3(pos.x * 2.0, 0.0, pos.z * 2.0);
    }
  }
  
  void _updateCameraTarget() {
    if (_tileMap?.playerSpawn != null) {
      final spawn = _tileMap!.playerSpawn!;
      _cameraTarget = Vector3(spawn.x * 2.0, 0.0, spawn.z * 2.0);
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
    
    // Load objects in viewport around camera target
    await _loadObjectsAroundCamera();
    
    _updateCameraTarget();
    notifyListeners();
  }
  
  /// Load objects in the viewport around the current camera target
  Future<void> _loadObjectsAroundCamera() async {
    if (_tileMap == null) return;
    
    final cameraX = (_cameraTarget.x / 2.0).round();
    final cameraZ = (_cameraTarget.z / 2.0).round();
    final radius = (_viewportRadius / 2.0).round();
    
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
            objectsToPlace.add(addObject(
              modelPath: modelData['path']!,
              displayName: modelData['name']!,
              gridX: x,
              gridZ: z,
            ));
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
        // Always show walls with variety
        final variant = (position.x + position.z) % 3;
        switch (variant) {
          case 0: return 'fence';
          case 1: return 'grave';
          case 2: return 'tree';
          default: return 'fence';
        }
      case TileType.obstacle:
        // Always show obstacles with variety
        final variant = (position.x * 3 + position.z * 7) % 4;
        switch (variant) {
          case 0: return 'crypt';
          case 1: return 'grave';
          case 2: return 'tree';
          case 3: return 'pumpkin';
          default: return 'crypt';
        }
      case TileType.candy:
        // Always show candy items
        final variant = (position.x * 5 + position.z * 13) % 3;
        switch (variant) {
          case 0: return 'candy_apple';
          case 1: return 'candy_chocolate';
          case 2: return 'candy_lollipop';
          default: return 'candy_apple';
        }
      case TileType.floor:
        // Show decorative items more frequently to visualize pathways
        if ((position.x * 11 + position.z * 17) % 20 == 0) {
          return 'lantern';
        }
        return null; // Most floor tiles remain empty for navigation
    }
  }

  static const Map<String, Map<String, String>> _modelLibrary = {
    // Walls and barriers
    'grave': {'path': 'assets/graveyard/gravestone-flat.obj', 'name': 'Grave'},
    'cross': {'path': 'assets/graveyard/gravestone-cross.obj', 'name': 'Cross'},
    'tree': {'path': 'assets/graveyard/pine.obj', 'name': 'Tree'},
    'fence': {'path': 'assets/graveyard/fence.obj', 'name': 'Fence'},
    
    // Obstacles and structures
    'crypt': {'path': 'assets/graveyard/crypt-small.obj', 'name': 'Crypt'},
    'pumpkin': {'path': 'assets/graveyard/pumpkin-carved.obj', 'name': 'Pumpkin'},
    
    // Characters (for future use)
    'zombie': {'path': 'assets/graveyard/character-zombie.obj', 'name': 'Zombie'},
    'skeleton': {'path': 'assets/graveyard/character-skeleton.obj', 'name': 'Skeleton'},
    'ghost': {'path': 'assets/graveyard/character-ghost.obj', 'name': 'Ghost'},
    
    // Decorative items
    'lantern': {'path': 'assets/graveyard/lantern-candle.obj', 'name': 'Lantern'},
    
    // Candy items using food models
    'candy_apple': {'path': 'assets/foods/apple.obj', 'name': 'Candy Apple'},
    'candy_chocolate': {'path': 'assets/foods/chocolate.obj', 'name': 'Chocolate'},
    'candy_lollipop': {'path': 'assets/foods/lollypop.obj', 'name': 'Lollipop'},
    'candy_cookie': {'path': 'assets/foods/cookie.obj', 'name': 'Cookie'},
    'candy_donut': {'path': 'assets/foods/donut.obj', 'name': 'Donut'},
    'candy_cupcake': {'path': 'assets/foods/cupcake.obj', 'name': 'Cupcake'},
  };
}
