import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Matrix4;
import 'package:vector_math/vector_math_64.dart' as vm64;

import '../models/model_3d.dart';
import '../core/tile_map.dart';
import '../core/tile_type.dart';
import '../core/position.dart';
import '../core/ghost_character.dart';
import '../core/enemy_manager.dart';
import '../core/enemy_character.dart';
import '../core/game_loop_manager.dart';
import '../core/ally_character.dart';
import '../core/animation_system.dart';
import '../core/dialogue_manager.dart';
import '../core/candy_item.dart';
import '../core/candy_collection_system.dart';
import '../core/collection_feedback.dart';

class GridObject {
  final String modelPath;
  final String displayName;
  Model3D? model;
  final int gridX;
  final int gridZ;
  final double rotationY; // Rotation around Y-axis in radians

  /// Optional animated world position (overrides gridX/gridZ when present)
  Vector3? _animatedWorldPosition;

  GridObject({
    required this.modelPath,
    required this.displayName,
    required this.gridX,
    required this.gridZ,
    this.model,
    this.rotationY = 0.0,
  });

  /// Get the current world position (animated or static)
  Vector3 get worldPosition {
    return _animatedWorldPosition ??
        Vector3(
          gridX * Position.tileSpacing,
          0.0,
          gridZ * Position.tileSpacing,
        );
  }

  /// Set the animated world position
  void setAnimatedPosition(Vector3? position) {
    _animatedWorldPosition = position;
  }

  /// Whether this object is currently using animated position
  bool get isAnimated => _animatedWorldPosition != null;

  /// Clear animated position and return to grid position
  void clearAnimatedPosition() {
    _animatedWorldPosition = null;
  }

  /// Create a copy with updated grid position
  GridObject copyWithGridPosition(int newGridX, int newGridZ) {
    return GridObject(
      modelPath: modelPath,
      displayName: displayName,
      model: model,
      gridX: newGridX,
      gridZ: newGridZ,
      rotationY: rotationY,
    );
  }

  vm64.Matrix4 get modelMatrix {
    final matrix = vm64.Matrix4.identity();
    final worldPos64 = vm64.Vector3(worldPosition.x, worldPosition.y, worldPosition.z);
    matrix.translateByVector3(worldPos64);
    if (rotationY != 0.0) {
      matrix.rotateY(rotationY);
    }
    return matrix;
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

  // Game loop manager for combat and systems
  GameLoopManager? _gameLoopManager;

  // Dialogue manager for narrative and feedback
  final DialogueManager _dialogueManager = DialogueManager();

  // Unified animation system for smooth transitions (replaces all wrapper systems)
  final AnimationSystem _animationSystem = AnimationSystem();

  // Removed legacy wrappers - using _animationSystem directly

  // Candy collection system
  final CandyCollectionSystem _candyCollectionSystem = CandyCollectionSystem();

  // Collection feedback manager
  final CollectionFeedbackManager _collectionFeedbackManager =
      CollectionFeedbackManager();

  // Camera and viewport management for large world
  Vector3 _cameraTarget = Vector3(10, 0, 10);
  final double _viewportRadius = 50.0; // Only render objects within this radius

  // Player position tracking for animations
  Position? _lastPlayerPosition;

  // Enemy and ally position tracking for animations
  final Map<String, Position> _lastEnemyPositions = {};
  final Map<String, Position> _lastAllyPositions = {};

  // Constructor for large world
  GridSceneManager.withTileMap(this._tileMap) {
    if (_tileMap != null) {
      _updateCameraTarget();
    }

    // Using unified animation system directly

    // Listen to unified animation system updates
    _animationSystem.addListener(() {
      _cameraTarget = _animationSystem.currentCameraPosition;
      _updateCharacterAnimationPositions();
      notifyListeners();
    });
  }

  // Default constructor for backward compatibility
  GridSceneManager() : _tileMap = null {
    // Using unified animation system directly

    // Listen to unified animation system updates
    _animationSystem.addListener(() {
      _cameraTarget = _animationSystem.currentCameraPosition;
      _updateCharacterAnimationPositions();
      notifyListeners();
    });
  }

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

    // Add ally objects from game loop manager
    _addAllyObjectsToRender(objects);

    return objects;
  }

  List<GridObject> _getObjectsInViewport() {
    final viewportObjects = <GridObject>[];
    final cameraX =
        _cameraTarget.x /
        Position.tileSpacing; // Convert world to grid coordinates
    final cameraZ = _cameraTarget.z / Position.tileSpacing;
    final radius =
        _viewportRadius / Position.tileSpacing; // Convert to grid units

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
  Vector3 get cameraTarget => _animationSystem.currentCameraPosition;

  // Get unified animation system (replaces both camera and character systems)
  AnimationSystem get animationSystem => _animationSystem;

  // Get the ghost character
  GhostCharacter? get ghostCharacter => _ghostCharacter;

  // Get the enemy manager
  EnemyManager? get enemyManager => _enemyManager;

  // Get the game loop manager
  GameLoopManager? get gameLoopManager => _gameLoopManager;

  /// Get the dialogue manager instance
  DialogueManager get dialogueManager => _dialogueManager;

  /// Get the candy collection system
  CandyCollectionSystem get candyCollectionSystem => _candyCollectionSystem;

  /// Get the collection feedback manager
  CollectionFeedbackManager get collectionFeedbackManager =>
      _collectionFeedbackManager;

  // Update camera target (for following player character later)
  void updateCameraTarget(Vector3 newTarget) {
    _cameraTarget = newTarget;
    _animationSystem.setCameraPosition(newTarget);
    // Reload objects around new camera position for large world
    if (_tileMap != null) {
      _loadObjectsAroundCamera();
    }
    notifyListeners();
  }

  /// Adds the ghost character to the scene
  Future<void> addGhostCharacter(GhostCharacter character) async {
    _ghostCharacter = character;

    // Set animation system reference for character movement coordination
    character.setAnimationSystem(_animationSystem);

    // Create a GridObject for the character
    final characterObject = GridObject(
      modelPath: character.modelPath,
      displayName: character.id,
      gridX: character.position.x,
      gridZ: character.position.z,
      rotationY: character.facingDirection.rotationY,
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
        rotationY: character.facingDirection.rotationY,
      );
    }

    // Update camera to follow the character (no animation for adding character)
    await _updateCameraToFollowCharacter(animate: false);
    notifyListeners();
  }

  /// Updates the ghost character's position in the scene
  Future<void> updateGhostCharacterPosition({Position? fromPosition}) async {
    if (_ghostCharacter == null) return;

    final character = _ghostCharacter!;
    final currentPosition = character.position;

    // Store the actual previous position at the moment of movement
    // This ensures we have the correct starting position for animations
    if (fromPosition != null) {
      _lastPlayerPosition = fromPosition;
    } else {
      // If no fromPosition provided, use the last known position
      // This prevents animation desync during rapid inputs
      if (_lastPlayerPosition == null) {
        _lastPlayerPosition = currentPosition;
      }
    }

    // Update or create the character object with new grid position
    final characterObject = GridObject(
      modelPath: character.modelPath,
      displayName: character.id,
      gridX: currentPosition.x,
      gridZ: currentPosition.z,
      model: character.model,
      rotationY: character.facingDirection.rotationY,
    );

    _characterObjects[character.id] = characterObject;

    // Reload objects around new position for large world
    if (_tileMap != null) {
      _loadObjectsAroundCamera();
    }

    // Always update camera to follow player - smooth animation system will handle transitions
    debugPrint(
      'GridSceneManager: Immediately syncing camera to player position',
    );

    // Use immediate camera sync instead of animation - the camera animation system will smooth this out
    final newCameraTarget = Vector3(
      currentPosition.x * Position.tileSpacing,
      0.0,
      currentPosition.z * Position.tileSpacing,
    );

    // Set the camera target immediately - the animation system will smoothly follow
    _animationSystem.animateCamera(newCameraTarget, duration: 100);
    _cameraTarget = newCameraTarget;

    // Notify game loop manager of player movement (this will handle animations)
    if (_gameLoopManager != null) {
      await _gameLoopManager!.onPlayerMoved();
    }

    // Update dialogue system
    _dialogueManager.update();

    notifyListeners();
  }

  /// Updates character animation positions for all animated characters
  void _updateCharacterAnimationPositions() {
    for (final entry in _characterObjects.entries) {
      final characterId = entry.key;
      final gridObject = entry.value;

      // Get current animated position from animation system
      final animatedPosition = _animationSystem.getCharacterWorldPosition(
        characterId,
      );

      if (animatedPosition != null) {
        // Character is animating, use animated position
        gridObject.setAnimatedPosition(animatedPosition);
      } else {
        // Character is not animating, clear animated position
        // Grid position should already be updated by animation completion callbacks
        gridObject.clearAnimatedPosition();
      }
    }
  }

  /// Animate character movement from current position to new position
  Future<void> animateCharacterMovement(
    String characterId,
    Position fromPosition,
    Position toPosition, {
    int? duration,
    AnimationEasing? easing,
  }) async {
    // Use easing directly (already converted to AnimationEasing)
    final unifiedEasing = easing ?? AnimationEasing.easeInOut;

    try {
      await _animationSystem.animateCharacter(
        characterId,
        fromPosition,
        toPosition,
        duration: duration,
        easing: unifiedEasing,
        onUpdate: (worldPosition) {
          // Update the character's GridObject with animated position
          final gridObject = _characterObjects[characterId];
          if (gridObject != null) {
            gridObject.setAnimatedPosition(worldPosition);
            // Trigger re-render
            notifyListeners();
          }
        },
      );
    } finally {
      // Ensure GridObject position is updated to final position regardless of how animation ended
      _updateCharacterGridPosition(characterId, toPosition);
      debugPrint('GridSceneManager: Character $characterId animation ended, final position: $toPosition');
    }
  }

  /// Animate enemy movement from current position to new position
  Future<void> animateEnemyMovement(
    String enemyId,
    Position fromPosition,
    Position toPosition,
  ) async {
    try {
      await _animationSystem.animateCharacter(
        enemyId,
        fromPosition,
        toPosition,
        easing: AnimationEasing.easeOut,
        onUpdate: (worldPosition) {
          // Update the enemy's GridObject with animated position
          final gridObject = _characterObjects[enemyId];
          if (gridObject != null) {
            gridObject.setAnimatedPosition(worldPosition);
            // Trigger re-render
            notifyListeners();
          }
        },
      );
    } finally {
      // Ensure GridObject position is updated to final position regardless of how animation ended
      _updateCharacterGridPosition(enemyId, toPosition);
      debugPrint('GridSceneManager: Enemy $enemyId animation ended, final position: $toPosition');
    }
  }

  /// Animate ally movement from current position to new position
  Future<void> animateAllyMovement(
    String allyId,
    Position fromPosition,
    Position toPosition,
  ) async {
    try {
      await _animationSystem.animateCharacter(
        allyId,
        fromPosition,
        toPosition,
        easing: AnimationEasing.easeInOut,
        onUpdate: (worldPosition) {
          // Update the ally's GridObject with animated position
          final gridObject = _characterObjects[allyId];
          if (gridObject != null) {
            gridObject.setAnimatedPosition(worldPosition);
            // Trigger re-render
            notifyListeners();
          }
        },
      );
    } finally {
      // Ensure GridObject position is updated to final position regardless of how animation ended
      _updateCharacterGridPosition(allyId, toPosition);
      debugPrint('GridSceneManager: Ally $allyId animation ended, final position: $toPosition');
    }
  }

  /// Store enemy position for animation tracking
  void trackEnemyPosition(String enemyId, Position position) {
    _lastEnemyPositions[enemyId] = position;
  }

  /// Store ally position for animation tracking
  void trackAllyPosition(String allyId, Position position) {
    _lastAllyPositions[allyId] = position;
  }

  /// Get last known enemy position
  Position? getLastEnemyPosition(String enemyId) {
    return _lastEnemyPositions[enemyId];
  }

  /// Get last known ally position
  Position? getLastAllyPosition(String allyId) {
    return _lastAllyPositions[allyId];
  }

  /// Update character's GridObject grid position after animation
  void _updateCharacterGridPosition(String characterId, Position newPosition) {
    final gridObject = _characterObjects[characterId];
    if (gridObject != null) {
      final updatedGridObject = gridObject.copyWithGridPosition(
        newPosition.x,
        newPosition.z,
      );
      _characterObjects[characterId] = updatedGridObject;
    }
  }

  /// Handle player movement animation (called during animation phase)
  Future<void> _handlePlayerMovementAnimation() async {
    if (_ghostCharacter == null) return;

    // Get stored previous and current positions from main.dart tracking
    final currentPosition = _ghostCharacter!.position;

    // Use the stored previous position - it should be set correctly in updateGhostCharacterPosition
    Position? previousPosition = _lastPlayerPosition;

    // If this is the first move or no previous position, don't animate
    if (previousPosition == null || previousPosition == currentPosition) {
      debugPrint('GridSceneManager: No movement to animate');
      return;
    }

    debugPrint(
      'GridSceneManager: Animating player movement from $previousPosition to $currentPosition',
    );

    // Start both character movement and camera animations in parallel
    final characterAnimationFuture = animateCharacterMovement(
      _ghostCharacter!.id,
      previousPosition,
      currentPosition,
      easing: AnimationEasing.easeInOut,
    );

    final cameraAnimationFuture = _updateCameraToFollowCharacter(animate: true);

    // Wait for both animations to complete
    await Future.wait([characterAnimationFuture, cameraAnimationFuture]);

    // Note: _updateCharacterGridPosition is now handled in the finally block of animateCharacterMovement

    debugPrint('GridSceneManager: Player movement animation completed');
  }

  /// Updates camera to follow the ghost character
  Future<void> _updateCameraToFollowCharacter({bool animate = true}) async {
    if (_ghostCharacter != null) {
      final pos = _ghostCharacter!.position;
      final newCameraTarget = Vector3(
        pos.x * Position.tileSpacing,
        0.0,
        pos.z * Position.tileSpacing,
      );

      if (animate) {
        debugPrint(
          'GridSceneManager: Starting camera animation to $newCameraTarget',
        );
        // Use shorter duration for responsive camera following
        await _animationSystem.animateCamera(
          newCameraTarget,
          duration: 100, // Fast camera following for responsive feel
          easing: AnimationEasing.easeInOut,
        );
        debugPrint('GridSceneManager: Camera animation completed');
      } else {
        debugPrint(
          'GridSceneManager: Setting camera position instantly to $newCameraTarget',
        );
        _animationSystem.setCameraPosition(newCameraTarget);
      }
      _cameraTarget = newCameraTarget;

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
      rotationY: enemy.facingDirection.rotationY,
    );

    _characterObjects[enemy.id] = enemyObject;
  }

  /// Adds the boss to the scene for rendering
  Future<void> _addBossToScene() async {
    if (_gameLoopManager?.bossManager.currentBoss != null) {
      final boss = _gameLoopManager!.bossManager.currentBoss!;

      final bossObject = GridObject(
        modelPath: boss.modelPath,
        displayName: boss.id,
        gridX: boss.position.x,
        gridZ: boss.position.z,
        model: boss.model,
        rotationY: boss.facingDirection.rotationY,
      );

      _characterObjects[boss.id] = bossObject;
      debugPrint('GridSceneManager: Added boss ${boss.id} to scene at ${boss.position}');
    }
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
        rotationY: enemy.facingDirection.rotationY,
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
      final initialTarget = Vector3(
        spawn.x * Position.tileSpacing,
        0.0,
        spawn.z * Position.tileSpacing,
      );
      _cameraTarget = initialTarget;
      _animationSystem.initialize(initialTarget);
    }
  }

  Future<void> addObject({
    required String modelPath,
    required String displayName,
    required int gridX,
    required int gridZ,
    double rotationY = 0.0,
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
      rotationY: rotationY,
    );

    _objects[key] = newObject;
    notifyListeners();

    try {
      final model = await Model3D.loadFromAssetCached(displayName, modelPath);
      _objects[key] = GridObject(
        modelPath: modelPath,
        displayName: displayName,
        gridX: gridX,
        gridZ: gridZ,
        model: model,
        rotationY: rotationY,
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

  /// Initialize and start the game loop manager
  Future<void> initializeGameLoop() async {
    if (_ghostCharacter != null && _enemyManager != null && _tileMap != null) {
      _gameLoopManager = GameLoopManager();
      _gameLoopManager!.initialize(
        ghostCharacter: _ghostCharacter!,
        enemyManager: _enemyManager!,
        tileMap: _tileMap!,
        dialogueManager: _dialogueManager,
        candyCollectionSystem: _candyCollectionSystem,
        collectionFeedbackManager: _collectionFeedbackManager,
        onEnemyDefeated: (enemyId) {
          // Remove the defeated enemy's 3D model from the scene
          removeEnemyFromScene(enemyId);
        },
        onCandyCollected: (position) {
          // Remove candy from tile map and 3D scene
          _removeCandyFromScene(position);
        },
        onMovementAnimation: () async {
          // Trigger both character and camera animations
          await _handlePlayerMovementAnimation();
        },
        onAnimateEnemyMovement:
            (String enemyId, Position fromPosition, Position toPosition) async {
              // Animate enemy movement
              await animateEnemyMovement(enemyId, fromPosition, toPosition);
            },
        onAnimateAllyMovement:
            (String allyId, Position fromPosition, Position toPosition) async {
              // Animate ally movement
              await animateAllyMovement(allyId, fromPosition, toPosition);
            },
      );

      // Initialize turn-based system
      _gameLoopManager!.initializeTurnBasedSystem();

      // Spawn the boss at the designated location
      if (_tileMap!.bossLocation != null) {
        debugPrint('GridSceneManager: Spawning boss at ${_tileMap!.bossLocation}');
        await _gameLoopManager!.spawnBoss(_tileMap!.bossLocation!);
        await _addBossToScene();
      }

      // Listen for game loop updates
      _gameLoopManager!.addListener(_onGameLoopUpdate);

      debugPrint('GridSceneManager: Turn-based system initialized');
    }
  }

  /// Called when game loop updates (for rendering ally positions)
  void _onGameLoopUpdate() {
    // Update enemy rendering positions
    updateEnemyPositions();

    // Update ally rendering positions
    notifyListeners();
  }

  /// Load objects in the viewport around the current camera target
  Future<void> _loadObjectsAroundCamera() async {
    if (_tileMap == null) return;

    final loadObjectsStopwatch = Stopwatch()..start();

    final cameraX = (_cameraTarget.x / Position.tileSpacing).round();
    final cameraZ = (_cameraTarget.z / Position.tileSpacing).round();
    final radius = (_viewportRadius / Position.tileSpacing).round();

    debugPrint(
      'Loading objects in ${radius * 2}x${radius * 2} viewport around camera ($cameraX, $cameraZ)',
    );

    final objectsToPlace = <Future<void>>[];
    int tilesScanned = 0;
    int objectsToLoad = 0;

    // Load all tiles in the viewport area
    final scanStopwatch = Stopwatch()..start();
    for (int dz = -radius; dz <= radius; dz++) {
      for (int dx = -radius; dx <= radius; dx++) {
        tilesScanned++;
        final x = cameraX + dx;
        final z = cameraZ + dz;
        final position = Position(x, z);

        if (!_tileMap!.isValidPosition(position)) continue;

        final key = '${x}_$z';
        if (_objects.containsKey(key)) continue; // Already loaded

        final tileType = _tileMap!.getTileAt(position);
        final modelData = _getTileModelData(tileType, position);

        if (modelData != null && modelData.modelKey != null) {
          final libraryData = _modelLibrary[modelData.modelKey];
          if (libraryData != null) {
            objectsToLoad++;
            objectsToPlace.add(
              addObject(
                modelPath: libraryData['path']!,
                displayName: libraryData['name']!,
                gridX: x,
                gridZ: z,
                rotationY: modelData.rotation,
              ),
            );

            // Register candy items with the collection system
            if (tileType == TileType.candy) {
              _registerCandyWithCollectionSystem(position);
            }
          }
        }
      }
    }
    scanStopwatch.stop();
    debugPrint(
      'Tile scanning: ${scanStopwatch.elapsedMilliseconds}ms (scanned $tilesScanned tiles, found $objectsToLoad objects to load)',
    );

    // Execute all object placements
    final modelLoadStopwatch = Stopwatch()..start();
    await Future.wait(objectsToPlace);
    modelLoadStopwatch.stop();
    debugPrint(
      'Model loading: ${modelLoadStopwatch.elapsedMilliseconds}ms (loaded $objectsToLoad 3D models)',
    );

    loadObjectsStopwatch.stop();
    debugPrint(
      'Total _loadObjectsAroundCamera: ${loadObjectsStopwatch.elapsedMilliseconds}ms',
    );
  }

  /// Get the appropriate model key and rotation for a tile type and position
  ({String? modelKey, double rotation})? _getTileModelData(
    TileType tileType,
    Position position,
  ) {
    switch (tileType) {
      case TileType.wall:
        return _getSmartWallModelData(position);
      case TileType.obstacle:
        return (modelKey: _getSmartObstacleModel(position), rotation: 0.0);
      case TileType.candy:
        // Always show candy items based on actual candy type
        final candyType = _getCandyTypeForPosition(position);
        final modelKey = _getCandyModelKeyForType(candyType);
        return (modelKey: modelKey, rotation: 0.0);
      case TileType.floor:
        return null; // Most floor tiles remain empty for navigation
    }
  }

  /// Get smart wall model and rotation based on neighboring tiles
  ({String? modelKey, double rotation}) _getSmartWallModelData(
    Position position,
  ) {
    if (_tileMap == null) {
      // Fallback to old behavior if no tile map
      final variant = (position.x + position.z) % 3;
      switch (variant) {
        case 0:
          return (modelKey: 'fence', rotation: 0.0);
        case 1:
          return (modelKey: 'grave', rotation: 0.0);
        case 2:
          return (modelKey: 'tree', rotation: 0.0);
        default:
          return (modelKey: 'fence', rotation: 0.0);
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

    // Count non-wall adjacent tiles
    final isUpOpen = upTile != TileType.wall;
    final isDownOpen = downTile != TileType.wall;
    final isLeftOpen = leftTile != TileType.wall;
    final isRightOpen = rightTile != TileType.wall;

    final openCount = [
      isUpOpen,
      isDownOpen,
      isLeftOpen,
      isRightOpen,
    ].where((x) => x).length;

    // If any adjacent tile is not a wall, use brick-wall and rotate towards the opening
    if (openCount > 0) {
      // Determine rotation based on which direction is open
      double rotation = 0.0;

      if (isUpOpen && !isDownOpen && !isLeftOpen && !isRightOpen) {
        // Opening to the north - face north (no rotation)
        rotation = 0.0;
      } else if (isRightOpen && !isUpOpen && !isDownOpen && !isLeftOpen) {
        // Opening to the east - face east (90 degrees)
        rotation = -pi / 2.0;
      } else if (isDownOpen && !isUpOpen && !isLeftOpen && !isRightOpen) {
        // Opening to the south - face south (180 degrees)
        rotation = pi; // π
      } else if (isLeftOpen && !isUpOpen && !isDownOpen && !isRightOpen) {
        // Opening to the west - face west (270 degrees)
        rotation = -3.0 * pi / 2.0;
      } else {
        // Multiple openings or corner case - use default rotation
        rotation = 0.0;
      }

      // Check diagonal neighbors for curves
      final topRight = Position(position.x + 1, position.z - 1);
      final topLeft = Position(position.x - 1, position.z - 1);
      final bottomRight = Position(position.x + 1, position.z + 1);
      final bottomLeft = Position(position.x - 1, position.z + 1);

      final topRightTile = _tileMap!.getTileAt(topRight);
      final topLeftTile = _tileMap!.getTileAt(topLeft);
      final bottomRightTile = _tileMap!.getTileAt(bottomRight);
      final bottomLeftTile = _tileMap!.getTileAt(bottomLeft);

      final diagonalOpenCount = [
        topRightTile != TileType.wall,
        topLeftTile != TileType.wall,
        bottomRightTile != TileType.wall,
        bottomLeftTile != TileType.wall,
      ].where((x) => x).length;

      // If all adjacent are walls but only one diagonal is open, use curve
      if (openCount == 2 && diagonalOpenCount == 3) {
        if (topRightTile == TileType.wall) {
          rotation = -pi; // Top-right curve
        } else if (bottomRightTile == TileType.wall) {
          rotation = -3.0 * pi / 2.0; // Bottom-right curve
        } else if (bottomLeftTile == TileType.wall) {
          rotation = 0; // Bottom-left curve
        } else if (topLeftTile == TileType.wall) {
          rotation = -pi / 2.0; // Top-left curve
        }
        return (modelKey: 'brick-wall-curve-small', rotation: rotation);
      }

      return (modelKey: 'brick-wall', rotation: rotation);
    }

    // Use random graveyard decoration if completely surrounded by walls
    return _getRandomGraveyardDecoration(position);
  }

  /// Get random graveyard decoration using seeded random based on position
  ({String? modelKey, double rotation}) _getRandomGraveyardDecoration(
    Position position,
  ) {
    // Create seeded random based on position and world generator seed
    final seed =
        (position.x * 31 + position.z * 17) ^ 42; // Simple seed combination
    final random = Random(seed);

    // 50% chance for empty space (no decoration)
    if (random.nextBool()) {
      return (modelKey: null, rotation: 0.0);
    }

    // List of graveyard decoration models
    const graveyardDecorations = [
      'gravestone-flat',
      'gravestone-cross',
      'gravestone-bevel',
      'gravestone-round',
      'gravestone-broken',
      'gravestone-wide',
      'pumpkin-tall-carved',
      'rocks',
      'rocks-tall',
      'pine',
      'pine-crooked',
      'debris',
      'debris-wood',
      'trunk',
      'trunk-long',
      'shovel-dirt',
    ];

    // Select random decoration
    final decorationIndex = random.nextInt(graveyardDecorations.length);
    final decoration = graveyardDecorations[decorationIndex];

    // Random rotation (0, 90, 180, 270 degrees)
    final rotations = [0.0, -pi / 2, pi, -3 * pi / 2];
    final rotation = rotations[random.nextInt(rotations.length)];

    return (modelKey: decoration, rotation: rotation);
  }

  /// Get smart obstacle model based on neighboring tiles
  String _getSmartObstacleModel(Position position) {
    // Fallback to old behavior if no tile map
    final variant = (position.x * 3 + position.z * 7) % 3;
    switch (variant) {
      case 0:
        return 'crypt';
      case 1:
        return 'grave';
      case 2:
        return 'tree';
      default:
        return 'crypt';
    }
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

    // Graveyard decorations for non-corridor walls
    'gravestone-flat': {
      'path': 'assets/graveyard/gravestone-flat.obj',
      'name': 'Gravestone Flat',
    },
    'gravestone-cross': {
      'path': 'assets/graveyard/gravestone-cross.obj',
      'name': 'Gravestone Cross',
    },
    'gravestone-round': {
      'path': 'assets/graveyard/gravestone-round.obj',
      'name': 'Gravestone Round',
    },
    'gravestone-broken': {
      'path': 'assets/graveyard/gravestone-broken.obj',
      'name': 'Gravestone Broken',
    },
    'gravestone-wide': {
      'path': 'assets/graveyard/gravestone-wide.obj',
      'name': 'Gravestone Wide',
    },
    'rocks': {'path': 'assets/graveyard/rocks.obj', 'name': 'Rocks'},
    'rocks-tall': {
      'path': 'assets/graveyard/rocks-tall.obj',
      'name': 'Tall Rocks',
    },
    'pine': {'path': 'assets/graveyard/pine.obj', 'name': 'Pine Tree'},
    'pine-crooked': {
      'path': 'assets/graveyard/pine-crooked.obj',
      'name': 'Crooked Pine',
    },
    'pine-fall': {
      'path': 'assets/graveyard/pine-fall.obj',
      'name': 'Fallen Pine',
    },
    'debris': {'path': 'assets/graveyard/debris.obj', 'name': 'Stone Debris'},
    'debris-wood': {
      'path': 'assets/graveyard/debris-wood.obj',
      'name': 'Wood Debris',
    },

    // Obstacles and structures
    'crypt': {'path': 'assets/graveyard/crypt-small.obj', 'name': 'Crypt'},

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
    'candy_candyBar': {'path': 'assets/foods/candy-bar.obj', 'name': 'Candy Bar'},
    'candy_iceCream': {'path': 'assets/foods/ice-cream.obj', 'name': 'Ice Cream'},
    'candy_popsicle': {'path': 'assets/foods/popsicle.obj', 'name': 'Popsicle'},
    'candy_gingerbread': {'path': 'assets/foods/ginger-bread.obj', 'name': 'Gingerbread'},
    'candy_muffin': {'path': 'assets/foods/muffin.obj', 'name': 'Muffin'},
    'candy_pumpkin': {
      'path': 'assets/graveyard/pumpkin-carved.obj',
      'name': 'Pumpkin',
    },
  };

  /// Adds ally objects to the rendering list
  void _addAllyObjectsToRender(List<GridObject> objects) {
    if (_gameLoopManager == null) return;

    final allies = _gameLoopManager!.allyManager.allies;
    for (final ally in allies) {
      if (ally.isAlive) {
        // Get the appropriate model path based on ally's original enemy type
        final modelPath = _getAllyModelPath(ally);

        final allyObject = GridObject(
          modelPath: modelPath,
          displayName: ally.id,
          gridX: ally.position.x,
          gridZ: ally.position.z,
          model: ally.model,
          rotationY: ally.facingDirection.rotationY,
        );

        objects.add(allyObject);
      }
    }
  }

  /// Gets the model path for an ally based on their original enemy type
  String _getAllyModelPath(AllyCharacter ally) {
    // Use the original enemy's model path
    return ally.originalEnemy.modelPath;
  }

  /// Registers a candy item with the collection system based on position
  void _registerCandyWithCollectionSystem(Position position) {
    // Create a candy item based on the position (deterministic based on coordinates)
    final candyType = _getCandyTypeForPosition(position);
    final candyId = 'candy_${position.x}_${position.z}';
    final candy = CandyItem.create(candyType, candyId, position: position);

    // Add to collection system
    _candyCollectionSystem.addSingleCandy(candy);
  }

  /// Gets a deterministic candy type based on position
  CandyType _getCandyTypeForPosition(Position position) {
    final variant =
        (position.x * 5 + position.z * 13) % CandyType.values.length;
    return CandyType.values[variant];
  }

  /// Gets the appropriate model key for a candy type
  String _getCandyModelKeyForType(CandyType candyType) {
    switch (candyType) {
      case CandyType.candyBar:
        return 'candy_candyBar';
      case CandyType.chocolate:
        return 'candy_chocolate';
      case CandyType.cookie:
        return 'candy_cookie';
      case CandyType.cupcake:
        return 'candy_cupcake';
      case CandyType.donut:
        return 'candy_donut';
      case CandyType.iceCream:
        return 'candy_iceCream';
      case CandyType.lollipop:
        return 'candy_lollipop';
      case CandyType.popsicle:
        return 'candy_popsicle';
      case CandyType.gingerbread:
        return 'candy_gingerbread';
      case CandyType.muffin:
        return 'candy_muffin';
    }
  }

  /// Removes candy from the scene when collected
  void _removeCandyFromScene(Position position) {
    if (_tileMap != null) {
      // Remove candy from tile map (mark as floor)
      _tileMap!.setTileAt(position, TileType.floor);

      // Remove the 3D candy object from rendering
      removeObject(position.x, position.z);

      // Notify listeners to update rendering
      notifyListeners();

      debugPrint('GridSceneManager: Removed candy from scene at $position');
    }
  }

  /// Dispose resources when scene manager is destroyed
  @override
  void dispose() {
    _gameLoopManager?.stopTurnBasedSystem();
    _gameLoopManager?.removeListener(_onGameLoopUpdate);
    _gameLoopManager?.dispose();
    _animationSystem.dispose();
    super.dispose();
  }
}
