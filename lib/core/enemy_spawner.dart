import 'dart:math';
import 'package:flutter/foundation.dart';

import 'enemy_character.dart';
import 'position.dart';
import 'tile_map.dart';

/// Manages enemy spawning across the large world map
class EnemySpawner {
  /// Random number generator for spawning decisions
  static final Random _random = Random();

  /// Counter for generating unique enemy IDs
  static int _enemyIdCounter = 0;

  /// Default spawn density (enemies per 100 tiles)
  static const double defaultSpawnDensity = 0.8;

  /// Minimum distance between enemies
  static const int minEnemyDistance = 3;

  /// Minimum distance from player spawn
  static const int minPlayerDistance = 10;

  /// Maximum attempts to find a valid spawn position
  static const int maxSpawnAttempts = 50;

  /// Spawns enemies across the world map
  /// Returns a list of spawned enemies
  static List<EnemyCharacter> spawnEnemies(
    TileMap tileMap, {
    double spawnDensity = defaultSpawnDensity,
    Position? playerSpawn,
  }) {
    final enemies = <EnemyCharacter>[];
    final (width, height) = tileMap.dimensions;
    final totalTiles = width * height;

    // Calculate number of enemies to spawn
    final enemyCount = (totalTiles * spawnDensity / 100).round();

    debugPrint('Spawning $enemyCount enemies across ${width}x$height world...');

    // Get all walkable positions
    final walkablePositions = _getWalkablePositions(tileMap);

    // Filter positions based on distance constraints
    final validPositions = _filterValidSpawnPositions(
      walkablePositions,
      playerSpawn,
      tileMap,
    );

    if (validPositions.isEmpty) {
      debugPrint('Warning: No valid spawn positions found for enemies');
      return enemies;
    }

    // Spawn enemies
    for (int i = 0; i < enemyCount && validPositions.isNotEmpty; i++) {
      final enemy = _spawnSingleEnemy(validPositions, enemies, tileMap);
      if (enemy != null) {
        enemies.add(enemy);
      }
    }

    debugPrint('Successfully spawned ${enemies.length} enemies');
    return enemies;
  }

  /// Spawns enemies in a specific region of the map
  static List<EnemyCharacter> spawnEnemiesInRegion(
    TileMap tileMap,
    Position topLeft,
    Position bottomRight, {
    double spawnDensity = defaultSpawnDensity,
    List<EnemyCharacter>? existingEnemies,
  }) {
    final enemies = <EnemyCharacter>[];
    final regionWidth = bottomRight.x - topLeft.x + 1;
    final regionHeight = bottomRight.z - topLeft.z + 1;
    final regionTiles = regionWidth * regionHeight;

    // Calculate number of enemies to spawn in this region
    final enemyCount = (regionTiles * spawnDensity / 100).round();

    // Get walkable positions in the region
    final walkablePositions = <Position>[];
    for (int z = topLeft.z; z <= bottomRight.z; z++) {
      for (int x = topLeft.x; x <= bottomRight.x; x++) {
        final position = Position(x, z);
        if (tileMap.isWalkable(position)) {
          walkablePositions.add(position);
        }
      }
    }

    // Filter positions to avoid existing enemies
    final validPositions = _filterPositionsFromExistingEnemies(
      walkablePositions,
      existingEnemies ?? [],
    );

    // Spawn enemies
    for (int i = 0; i < enemyCount && validPositions.isNotEmpty; i++) {
      final enemy = _spawnSingleEnemy(validPositions, enemies, tileMap);
      if (enemy != null) {
        enemies.add(enemy);
      }
    }

    return enemies;
  }

  /// Spawns a single enemy at a strategic location
  static EnemyCharacter? spawnSingleEnemyAt(
    Position position,
    TileMap tileMap, {
    EnemyType? enemyType,
    EnemyAIType? aiType,
  }) {
    if (!tileMap.isWalkable(position)) {
      return null;
    }

    final enemy = _createEnemy(position, enemyType, aiType);
    return enemy;
  }

  /// Gets all walkable positions in the tile map
  static List<Position> _getWalkablePositions(TileMap tileMap) {
    final positions = <Position>[];
    final (width, height) = tileMap.dimensions;

    for (int z = 0; z < height; z++) {
      for (int x = 0; x < width; x++) {
        final position = Position(x, z);
        if (tileMap.isWalkable(position)) {
          positions.add(position);
        }
      }
    }

    return positions;
  }

  /// Filters positions based on distance constraints
  static List<Position> _filterValidSpawnPositions(
    List<Position> positions,
    Position? playerSpawn,
    TileMap tileMap,
  ) {
    final validPositions = <Position>[];

    for (final position in positions) {
      // Skip perimeter positions (too close to walls)
      if (tileMap.isPerimeterPosition(position)) {
        continue;
      }

      // Check distance from player spawn
      if (playerSpawn != null) {
        final distanceFromPlayer = position.distanceTo(playerSpawn);
        if (distanceFromPlayer < minPlayerDistance) {
          continue;
        }
      }

      // Check distance from boss location
      final bossLocation = tileMap.bossLocation;
      if (bossLocation != null) {
        final distanceFromBoss = position.distanceTo(bossLocation);
        if (distanceFromBoss < 5) {
          continue; // Keep area around boss clear
        }
      }

      validPositions.add(position);
    }

    return validPositions;
  }

  /// Filters positions to avoid existing enemies
  static List<Position> _filterPositionsFromExistingEnemies(
    List<Position> positions,
    List<EnemyCharacter> existingEnemies,
  ) {
    final validPositions = <Position>[];

    for (final position in positions) {
      bool tooClose = false;

      for (final enemy in existingEnemies) {
        if (position.distanceTo(enemy.position) < minEnemyDistance) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        validPositions.add(position);
      }
    }

    return validPositions;
  }

  /// Spawns a single enemy at a valid position
  static EnemyCharacter? _spawnSingleEnemy(
    List<Position> validPositions,
    List<EnemyCharacter> existingEnemies,
    TileMap tileMap,
  ) {
    if (validPositions.isEmpty) return null;

    // Try multiple times to find a good position
    for (int attempt = 0; attempt < maxSpawnAttempts; attempt++) {
      final randomIndex = _random.nextInt(validPositions.length);
      final position = validPositions[randomIndex];

      // Check distance from existing enemies
      bool tooClose = false;
      for (final enemy in existingEnemies) {
        if (position.distanceTo(enemy.position) < minEnemyDistance) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        // Remove this position from valid positions
        validPositions.removeAt(randomIndex);

        // Create and return the enemy
        return _createEnemy(position);
      }

      // Remove the invalid position and try again
      validPositions.removeAt(randomIndex);
      if (validPositions.isEmpty) break;
    }

    return null;
  }

  /// Creates an enemy character with random or specified attributes
  static EnemyCharacter _createEnemy(
    Position position, [
    EnemyType? enemyType,
    EnemyAIType? aiType,
  ]) {
    final id = 'enemy_${_enemyIdCounter++}';
    final selectedEnemyType = enemyType ?? _getRandomEnemyType();
    final selectedAIType = aiType ?? _getRandomAIType();

    switch (selectedEnemyType) {
      case EnemyType.human:
        return EnemyCharacter.human(
          id: id,
          position: position,
          modelType: HumanModelType.random(),
          health: _random.nextInt(30) + 40, // 40-70 health
          maxHealth: _random.nextInt(30) + 40,
          aiType: selectedAIType,
          activationRadius: _getActivationRadius(selectedAIType),
        );

      case EnemyType.monster:
        return EnemyCharacter.monster(
          id: id,
          position: position,
          modelType: MonsterModelType.random(),
          health: _random.nextInt(40) + 60, // 60-100 health
          maxHealth: _random.nextInt(40) + 60,
          aiType: selectedAIType,
          activationRadius: _getActivationRadius(selectedAIType),
        );
    }
  }

  /// Gets a random enemy type with weighted distribution
  static EnemyType _getRandomEnemyType() {
    // 70% chance for human, 30% chance for monster
    return _random.nextDouble() < 0.7 ? EnemyType.human : EnemyType.monster;
  }

  /// Gets a random AI type with weighted distribution
  static EnemyAIType _getRandomAIType() {
    final rand = _random.nextDouble();
    if (rand < 0.4) {
      return EnemyAIType.wanderer; // 40% wanderers
    } else if (rand < 0.7) {
      return EnemyAIType.aggressive; // 30% aggressive
    } else {
      return EnemyAIType.guard; // 30% guards
    }
  }

  /// Gets activation radius based on AI type
  static int _getActivationRadius(EnemyAIType aiType) {
    switch (aiType) {
      case EnemyAIType.aggressive:
        return 12; // Aggressive enemies detect from farther away
      case EnemyAIType.wanderer:
        return 8; // Standard detection range
      case EnemyAIType.guard:
        return 6; // Guards have shorter detection range
    }
  }

  /// Spawns boss enemy at the specified location
  static EnemyCharacter spawnBoss(Position position) {
    final id = 'boss_${_enemyIdCounter++}';

    return EnemyCharacter.monster(
      id: id,
      position: position,
      modelType: MonsterModelType.vampire, // Use vampire as boss model
      health: 200,
      maxHealth: 200,
      aiType: EnemyAIType.aggressive,
      activationRadius: 15, // Boss has large detection range
    );
  }

  /// Resets the enemy ID counter (useful for testing)
  static void resetIdCounter() {
    _enemyIdCounter = 0;
  }
}

/// Types of enemies that can be spawned
enum EnemyType {
  human,
  monster;

  String get displayName {
    switch (this) {
      case EnemyType.human:
        return 'Human';
      case EnemyType.monster:
        return 'Monster';
    }
  }
}
