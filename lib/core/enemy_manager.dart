import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'enemy_character.dart';
import 'enemy_spawner.dart';
import 'position.dart';
import 'tile_map.dart';

/// Manages all enemies in the game world
class EnemyManager {
  /// All enemies in the game world
  final Map<String, EnemyCharacter> _enemies = {};

  /// Reference to the tile map for validation
  TileMap? _tileMap;

  /// Player position for proximity calculations
  Position? _playerPosition;

  /// Gets all enemies in the game
  UnmodifiableMapView<String, EnemyCharacter> get enemies =>
      UnmodifiableMapView(_enemies);

  /// Gets all active enemies (for performance optimization)
  List<EnemyCharacter> get activeEnemies =>
      _enemies.values.where((enemy) => enemy.isActive).toList();

  /// Gets all enemies at a specific position
  List<EnemyCharacter> getEnemiesAt(Position position) {
    return _enemies.values
        .where((enemy) => enemy.position == position)
        .toList();
  }

  /// Gets an enemy by ID
  EnemyCharacter? getEnemy(String id) {
    return _enemies[id];
  }

  /// Gets the number of enemies in the world
  int get enemyCount => _enemies.length;

  /// Gets the number of active enemies
  int get activeEnemyCount => activeEnemies.length;

  /// Initializes the enemy manager with a tile map
  void initialize(TileMap tileMap) {
    _tileMap = tileMap;
  }

  /// Spawns enemies across the world map
  Future<void> spawnEnemies({
    double spawnDensity = EnemySpawner.defaultSpawnDensity,
    Position? playerSpawn,
  }) async {
    if (_tileMap == null) {
      throw StateError('EnemyManager must be initialized with a TileMap first');
    }

    debugPrint('EnemyManager: Spawning enemies across the world...');

    // Use EnemySpawner to generate enemies
    final spawnedEnemies = EnemySpawner.spawnEnemies(
      _tileMap!,
      spawnDensity: spawnDensity,
      playerSpawn: playerSpawn,
    );

    // Add all spawned enemies to our management system
    for (final enemy in spawnedEnemies) {
      await addEnemy(enemy);
    }

    debugPrint('EnemyManager: Successfully spawned ${_enemies.length} enemies');
  }

  /// Spawns enemies in a specific region
  Future<void> spawnEnemiesInRegion(
    Position topLeft,
    Position bottomRight, {
    double spawnDensity = EnemySpawner.defaultSpawnDensity,
  }) async {
    if (_tileMap == null) {
      throw StateError('EnemyManager must be initialized with a TileMap first');
    }

    final spawnedEnemies = EnemySpawner.spawnEnemiesInRegion(
      _tileMap!,
      topLeft,
      bottomRight,
      spawnDensity: spawnDensity,
      existingEnemies: _enemies.values.toList(),
    );

    for (final enemy in spawnedEnemies) {
      await addEnemy(enemy);
    }
  }

  /// Adds an enemy to the manager
  Future<void> addEnemy(EnemyCharacter enemy) async {
    _enemies[enemy.id] = enemy;

    // Load the enemy's 3D model
    await enemy.loadModel();

    debugPrint(
      'EnemyManager: Added ${enemy.enemyType.displayName} '
      'at ${enemy.position} (${enemy.id})',
    );
  }

  /// Removes an enemy from the manager
  void removeEnemy(String enemyId) {
    final enemy = _enemies.remove(enemyId);
    if (enemy != null) {
      debugPrint(
        'EnemyManager: Removed ${enemy.enemyType.displayName} '
        '(${enemy.id})',
      );
    }
  }

  /// Spawns the boss enemy at the specified location
  Future<void> spawnBoss(Position bossLocation) async {
    final boss = EnemySpawner.spawnBoss(bossLocation);
    await addEnemy(boss);
    debugPrint('EnemyManager: Spawned boss at $bossLocation');
  }

  /// Updates enemy activation based on player position
  void updateEnemyActivation(Position playerPosition) {
    _playerPosition = playerPosition;

    // Update proximity detection and activation for all enemies
    for (final enemy in _enemies.values) {
      final distance = playerPosition.distanceTo(enemy.position);

      final shouldBeActive = distance <= enemy.activationRadius;

      if (shouldBeActive != enemy.isActive) {
        enemy.isActive = shouldBeActive;

        if (shouldBeActive) {
          debugPrint(
            'EnemyManager: Activated ${enemy.id} at distance $distance',
          );
        } else {
          debugPrint('EnemyManager: Deactivated ${enemy.id}');
        }
      }
    }
  }

  /// Gets all enemies within a certain radius of a position
  List<EnemyCharacter> getEnemiesInRadius(Position center, double radius) {
    return _enemies.values.where((enemy) {
      final distance = center.distanceTo(enemy.position);
      return distance <= radius;
    }).toList();
  }

  /// Gets all enemies within activation range of the player
  List<EnemyCharacter> getEnemiesInPlayerRange() {
    if (_playerPosition == null) return [];

    return getEnemiesInRadius(_playerPosition!, 15.0); // Max activation radius
  }

  /// Processes AI for all active enemies
  void processEnemyAI() {
    if (_playerPosition == null) return;

    for (final enemy in activeEnemies) {
      // Process enemy AI based on their type and state
      _processEnemyAI(enemy);
    }
  }

  /// Processes AI for a single enemy
  void _processEnemyAI(EnemyCharacter enemy) {
    if (_tileMap == null || _playerPosition == null) return;

    switch (enemy.aiType) {
      case EnemyAIType.wanderer:
        _processWandererAI(enemy);
        break;
      case EnemyAIType.aggressive:
        _processAggressiveAI(enemy);
        break;
      case EnemyAIType.guard:
        _processGuardAI(enemy);
        break;
    }
  }

  /// Processes wanderer AI (random movement)
  void _processWandererAI(EnemyCharacter enemy) {
    // Wanderers move randomly when active
    // This is a placeholder - full AI implementation would be in a separate task
  }

  /// Processes aggressive AI (moves toward player)
  void _processAggressiveAI(EnemyCharacter enemy) {
    // Aggressive enemies move toward the player when in range
    // This is a placeholder - full AI implementation would be in a separate task
  }

  /// Processes guard AI (stays in area)
  void _processGuardAI(EnemyCharacter enemy) {
    // Guards patrol a small area around their spawn point
    // This is a placeholder - full AI implementation would be in a separate task
  }

  /// Gets statistics about the enemy population
  Map<String, dynamic> getEnemyStats() {
    final stats = <String, dynamic>{
      'total_enemies': _enemies.length,
      'active_enemies': activeEnemyCount,
      'enemy_types': <String, int>{},
      'ai_types': <String, int>{},
    };

    for (final enemy in _enemies.values) {
      final enemyType = enemy.enemyType.displayName;
      final aiType = enemy.aiType.name;

      stats['enemy_types'][enemyType] =
          (stats['enemy_types'][enemyType] ?? 0) + 1;
      stats['ai_types'][aiType] = (stats['ai_types'][aiType] ?? 0) + 1;
    }

    return stats;
  }

  /// Clears all enemies from the manager
  void clearAllEnemies() {
    _enemies.clear();
    debugPrint('EnemyManager: Cleared all enemies');
  }

  /// Spawns enemies for testing without loading 3D models
  List<EnemyCharacter> spawnEnemiesForTesting({
    double spawnDensity = EnemySpawner.defaultSpawnDensity,
    Position? playerSpawn,
  }) {
    if (_tileMap == null) {
      throw StateError('EnemyManager must be initialized with a TileMap first');
    }

    debugPrint('EnemyManager: Spawning enemies for testing...');

    // Use EnemySpawner to generate enemies
    final spawnedEnemies = EnemySpawner.spawnEnemies(
      _tileMap!,
      spawnDensity: spawnDensity,
      playerSpawn: playerSpawn,
    );

    // Add all spawned enemies to our management system without loading models
    for (final enemy in spawnedEnemies) {
      _enemies[enemy.id] = enemy;
      debugPrint(
        'EnemyManager: Added ${enemy.enemyType.displayName} '
        'at ${enemy.position} (${enemy.id}) for testing',
      );
    }

    debugPrint(
      'EnemyManager: Successfully spawned ${_enemies.length} enemies for testing',
    );
    return spawnedEnemies;
  }

  /// Resets the enemy manager to initial state
  void reset() {
    clearAllEnemies();
    _tileMap = null;
    _playerPosition = null;
    EnemySpawner.resetIdCounter();
  }
}
