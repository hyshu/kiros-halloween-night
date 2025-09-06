import 'dart:math';

import 'character.dart';
import 'enemy_character.dart';
import 'ghost_character.dart';
import 'position.dart';

/// Handles proximity detection between characters for activation purposes
class ProximityDetector {
  /// Default activation radius for enemies
  static const int defaultActivationRadius = 8;
  
  /// Maximum distance to consider for any proximity calculations
  static const int maxProximityDistance = 20;

  /// Calculates the distance between two characters
  double calculateDistance(Character character1, Character character2) {
    return character1.position.distanceTo(character2.position).toDouble();
  }

  /// Calculates the distance between a character and a position
  double calculateDistanceToPosition(Character character, Position position) {
    return character.position.distanceTo(position).toDouble();
  }

  /// Checks if two characters are within proximity range
  bool areCharactersInProximity(Character character1, Character character2, int radius) {
    final distance = calculateDistance(character1, character2);
    return distance <= radius;
  }

  /// Checks if a character is within proximity of a position
  bool isCharacterInProximityOfPosition(Character character, Position position, int radius) {
    final distance = calculateDistanceToPosition(character, position);
    return distance <= radius;
  }

  /// Gets all enemies within activation range of the player
  List<EnemyCharacter> getEnemiesInActivationRange(
    GhostCharacter player, 
    List<EnemyCharacter> enemies
  ) {
    final activatedEnemies = <EnemyCharacter>[];
    
    for (final enemy in enemies) {
      final distance = calculateDistance(player, enemy);
      if (distance <= enemy.activationRadius) {
        activatedEnemies.add(enemy);
      }
    }
    
    return activatedEnemies;
  }

  /// Gets all enemies outside activation range of the player
  List<EnemyCharacter> getEnemiesOutsideActivationRange(
    GhostCharacter player, 
    List<EnemyCharacter> enemies
  ) {
    final deactivatedEnemies = <EnemyCharacter>[];
    
    for (final enemy in enemies) {
      final distance = calculateDistance(player, enemy);
      if (distance > enemy.activationRadius) {
        deactivatedEnemies.add(enemy);
      }
    }
    
    return deactivatedEnemies;
  }

  /// Gets all characters within a specific radius of a position
  List<T> getCharactersInRadius<T extends Character>(
    Position center, 
    List<T> characters, 
    int radius
  ) {
    final charactersInRange = <T>[];
    
    for (final character in characters) {
      final distance = calculateDistanceToPosition(character, center);
      if (distance <= radius) {
        charactersInRange.add(character);
      }
    }
    
    return charactersInRange;
  }

  /// Gets the closest character to a given position
  T? getClosestCharacter<T extends Character>(Position position, List<T> characters) {
    if (characters.isEmpty) return null;
    
    T? closest;
    double closestDistance = double.infinity;
    
    for (final character in characters) {
      final distance = calculateDistanceToPosition(character, position);
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = character;
      }
    }
    
    return closest;
  }

  /// Gets the closest enemy to the player
  EnemyCharacter? getClosestEnemyToPlayer(
    GhostCharacter player, 
    List<EnemyCharacter> enemies
  ) {
    return getClosestCharacter(player.position, enemies);
  }

  /// Checks if any enemies are within immediate threat range (adjacent tiles)
  bool hasImmediateThreat(GhostCharacter player, List<EnemyCharacter> enemies) {
    const immediateRange = 1;
    final threateningEnemies = getCharactersInRadius(
      player.position, 
      enemies.where((e) => e.isHostile).toList(), 
      immediateRange
    );
    return threateningEnemies.isNotEmpty;
  }

  /// Gets all hostile enemies within combat range
  List<EnemyCharacter> getHostileEnemiesInCombatRange(
    GhostCharacter player, 
    List<EnemyCharacter> enemies, 
    {int combatRange = 2}
  ) {
    return getCharactersInRadius(
      player.position, 
      enemies.where((e) => e.isHostile).toList(), 
      combatRange
    );
  }

  /// Gets all ally enemies within following range
  List<EnemyCharacter> getAllyEnemiesInFollowingRange(
    GhostCharacter player, 
    List<EnemyCharacter> enemies, 
    {int followingRange = 5}
  ) {
    return getCharactersInRadius(
      player.position, 
      enemies.where((e) => e.isAlly).toList(), 
      followingRange
    );
  }

  /// Calculates proximity score for prioritizing enemy processing
  /// Higher score means higher priority (closer enemies get higher scores)
  double calculateProximityScore(GhostCharacter player, EnemyCharacter enemy) {
    final distance = calculateDistance(player, enemy);
    
    // Avoid division by zero
    if (distance == 0) return double.maxFinite;
    
    // Closer enemies get higher scores
    final baseScore = maxProximityDistance / distance;
    
    // Hostile enemies get priority over allies
    final stateMultiplier = enemy.isHostile ? 1.5 : 1.0;
    
    // Active enemies get priority over inactive ones
    final activityMultiplier = enemy.isProximityActive ? 1.2 : 1.0;
    
    return baseScore * stateMultiplier * activityMultiplier;
  }

  /// Gets enemies sorted by proximity priority (closest and most threatening first)
  List<EnemyCharacter> getEnemiesByProximityPriority(
    GhostCharacter player, 
    List<EnemyCharacter> enemies
  ) {
    final enemiesWithScores = enemies.map((enemy) => {
      'enemy': enemy,
      'score': calculateProximityScore(player, enemy),
    }).toList();
    
    // Sort by score in descending order (highest priority first)
    enemiesWithScores.sort((a, b) => 
        (b['score'] as double).compareTo(a['score'] as double));
    
    return enemiesWithScores
        .map((item) => item['enemy'] as EnemyCharacter)
        .toList();
  }

  /// Checks if an enemy should be activated based on player proximity
  bool shouldActivateEnemy(GhostCharacter player, EnemyCharacter enemy) {
    final distance = calculateDistance(player, enemy);
    return distance <= enemy.activationRadius;
  }

  /// Checks if an enemy should be deactivated based on player proximity
  bool shouldDeactivateEnemy(GhostCharacter player, EnemyCharacter enemy) {
    final distance = calculateDistance(player, enemy);
    // Add a small buffer to prevent rapid activation/deactivation
    final deactivationRadius = enemy.activationRadius + 1;
    return distance > deactivationRadius;
  }

  /// Gets proximity information for debugging and monitoring
  ProximityInfo getProximityInfo(GhostCharacter player, List<EnemyCharacter> enemies) {
    final activeEnemies = enemies.where((e) => e.isProximityActive).toList();
    final inactiveEnemies = enemies.where((e) => !e.isProximityActive).toList();
    final closestEnemy = getClosestEnemyToPlayer(player, enemies);
    final immediateThreats = getHostileEnemiesInCombatRange(player, enemies, combatRange: 1);
    
    return ProximityInfo(
      totalEnemies: enemies.length,
      activeEnemies: activeEnemies.length,
      inactiveEnemies: inactiveEnemies.length,
      closestEnemyDistance: closestEnemy != null 
          ? calculateDistance(player, closestEnemy) 
          : null,
      immediateThreats: immediateThreats.length,
      averageDistanceToActiveEnemies: _calculateAverageDistance(player, activeEnemies),
    );
  }

  /// Calculates the average distance to a list of enemies
  double? _calculateAverageDistance(GhostCharacter player, List<EnemyCharacter> enemies) {
    if (enemies.isEmpty) return null;
    
    final totalDistance = enemies
        .map((enemy) => calculateDistance(player, enemy))
        .reduce((a, b) => a + b);
    
    return totalDistance / enemies.length;
  }
}

/// Information about proximity relationships for monitoring and debugging
class ProximityInfo {
  /// Total number of enemies in the game
  final int totalEnemies;
  
  /// Number of currently active enemies
  final int activeEnemies;
  
  /// Number of currently inactive enemies
  final int inactiveEnemies;
  
  /// Distance to the closest enemy (null if no enemies)
  final double? closestEnemyDistance;
  
  /// Number of enemies in immediate threat range
  final int immediateThreats;
  
  /// Average distance to all active enemies (null if no active enemies)
  final double? averageDistanceToActiveEnemies;

  const ProximityInfo({
    required this.totalEnemies,
    required this.activeEnemies,
    required this.inactiveEnemies,
    this.closestEnemyDistance,
    required this.immediateThreats,
    this.averageDistanceToActiveEnemies,
  });

  /// Gets the percentage of enemies that are currently active
  double get activationPercentage {
    if (totalEnemies == 0) return 0.0;
    return (activeEnemies / totalEnemies) * 100.0;
  }

  @override
  String toString() {
    return 'ProximityInfo(total: $totalEnemies, active: $activeEnemies, '
           'inactive: $inactiveEnemies, closest: ${closestEnemyDistance?.toStringAsFixed(1)}, '
           'threats: $immediateThreats, activation: ${activationPercentage.toStringAsFixed(1)}%)';
  }
}