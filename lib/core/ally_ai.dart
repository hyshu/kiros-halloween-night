import 'dart:math';
import 'ally_character.dart';
import 'enemy_character.dart';
import 'ghost_character.dart';
import 'position.dart';
import 'tile_map.dart';

/// AI system for managing ally behavior and combat engagement
class AllyAI {
  /// Random number generator for AI decisions
  static final Random _random = Random();

  /// Combat detection range for allies
  static const int combatDetectionRange = 4;

  /// Maximum distance allies will chase enemies
  static const int maxChaseDistance = 8;

  /// Minimum distance to maintain from player when following
  static const int minFollowDistance = 1;

  /// Maximum distance before ally tries to catch up to player
  static const int maxFollowDistance = 6;

  /// Updates AI for a single ally character
  static void updateAllyAI(
    AllyCharacter ally,
    GhostCharacter player,
    List<EnemyCharacter> hostileEnemies,
    TileMap tileMap,
  ) {
    if (!ally.isAlive || ally.isSatisfied) {
      return;
    }

    // Update movement cooldown
    if (ally.movementCooldown > 0) {
      ally.movementCooldown--;
      return;
    }

    // Check for nearby hostile enemies
    final nearbyEnemies = _findNearbyHostileEnemies(ally, hostileEnemies);

    if (nearbyEnemies.isNotEmpty && ally.state != AllyState.satisfied) {
      // Switch to combat mode
      if (ally.state != AllyState.combat) {
        ally.state = AllyState.combat;
      }
      _executeCombatAI(ally, nearbyEnemies, tileMap);
    } else {
      // Switch to following mode
      if (ally.state != AllyState.following) {
        ally.state = AllyState.following;
      }
      _executeFollowingAI(ally, player, tileMap);
    }
  }

  /// Updates AI for multiple allies
  static void updateAlliesAI(
    List<AllyCharacter> allies,
    GhostCharacter player,
    List<EnemyCharacter> hostileEnemies,
    TileMap tileMap,
  ) {
    for (final ally in allies) {
      updateAllyAI(ally, player, hostileEnemies, tileMap);
    }
  }

  /// Finds hostile enemies within combat detection range
  static List<EnemyCharacter> _findNearbyHostileEnemies(
    AllyCharacter ally,
    List<EnemyCharacter> hostileEnemies,
  ) {
    return hostileEnemies.where((enemy) {
      return enemy.isHostile &&
          enemy.isProximityActive &&
          enemy.isAlive &&
          ally.position.distanceTo(enemy.position) <= combatDetectionRange;
    }).toList();
  }

  /// Executes combat AI behavior
  static void _executeCombatAI(
    AllyCharacter ally,
    List<EnemyCharacter> nearbyEnemies,
    TileMap tileMap,
  ) {
    if (nearbyEnemies.isEmpty) {
      return;
    }

    // Find the closest enemy
    final closestEnemy = nearbyEnemies.reduce(
      (a, b) =>
          ally.position.distanceTo(a.position) <
              ally.position.distanceTo(b.position)
          ? a
          : b,
    );

    final distanceToEnemy = ally.position.distanceTo(closestEnemy.position);

    // If enemy is adjacent, stay in position for combat
    if (distanceToEnemy <= 1) {
      ally.setActive(); // Ally is engaged in combat
      return;
    }

    // If enemy is within chase range, move towards it
    if (distanceToEnemy <= maxChaseDistance) {
      _moveTowardsTarget(ally, closestEnemy.position, tileMap);
    } else {
      // Enemy too far, return to following mode
      ally.state = AllyState.following;
    }
  }

  /// Executes following AI behavior
  static void _executeFollowingAI(
    AllyCharacter ally,
    GhostCharacter player,
    TileMap tileMap,
  ) {
    final distanceToPlayer = ally.position.distanceTo(player.position);

    if (distanceToPlayer > maxFollowDistance) {
      // Too far from player, move closer quickly
      _moveTowardsTarget(ally, player.position, tileMap);
    } else if (distanceToPlayer > minFollowDistance) {
      // Move to preferred distance (1 tile away)
      _moveTowardsTarget(ally, player.position, tileMap);
    } else {
      // At good distance, occasionally move randomly or stay put
      if (_random.nextDouble() < 0.2) {
        // 20% chance to move randomly
        _wanderRandomly(ally, tileMap);
      } else {
        ally.setIdle();
      }
    }
  }

  /// Moves ally towards a target position with obstacle avoidance
  static void _moveTowardsTarget(
    AllyCharacter ally,
    Position target,
    TileMap tileMap,
  ) {
    final primaryDirection = _getBestDirectionTowards(ally.position, target);

    if (primaryDirection != null) {
      // Try primary direction first
      if (_attemptMove(ally, primaryDirection, tileMap)) {
        return; // Successfully moved in primary direction
      }

      // Primary direction blocked, try alternative paths
      final alternativeDirections = _getAlternativeDirections(
        ally.position,
        primaryDirection,
        target,
      );

      for (final direction in alternativeDirections) {
        if (_attemptMove(ally, direction, tileMap)) {
          return; // Successfully moved in alternative direction
        }
      }
    }

    // If no direct path available, try random movement as last resort
    _wanderRandomly(ally, tileMap);
  }

  /// Makes ally wander randomly
  static void _wanderRandomly(AllyCharacter ally, TileMap tileMap) {
    final directions = Direction.values;
    final shuffledDirections = List<Direction>.from(directions)
      ..shuffle(_random);

    for (final direction in shuffledDirections) {
      if (_attemptMove(ally, direction, tileMap)) {
        break; // Successfully moved
      }
    }
  }

  /// Gets the best direction to move towards a target
  static Direction? _getBestDirectionTowards(Position from, Position target) {
    final dx = target.x - from.x;
    final dz = target.z - from.z;

    // Prioritize the axis with the larger difference
    if (dx.abs() > dz.abs()) {
      return dx > 0 ? Direction.east : Direction.west;
    } else if (dz.abs() > dx.abs()) {
      return dz > 0 ? Direction.south : Direction.north;
    } else if (dx != 0) {
      return dx > 0 ? Direction.east : Direction.west;
    } else if (dz != 0) {
      return dz > 0 ? Direction.south : Direction.north;
    }

    return null; // Already at target
  }

  /// Gets alternative directions to try when primary direction is blocked
  static List<Direction> _getAlternativeDirections(
    Position from,
    Direction primaryDirection,
    Position target,
  ) {
    final dx = target.x - from.x;
    final dz = target.z - from.z;
    final alternatives = <Direction>[];

    // Add perpendicular directions based on the secondary axis
    switch (primaryDirection) {
      case Direction.north:
      case Direction.south:
        // Primary is vertical, try horizontal alternatives
        if (dx > 0) {
          alternatives.add(Direction.east);
        } else if (dx < 0) {
          alternatives.add(Direction.west);
        }
        // Add the opposite horizontal direction as backup
        if (dx >= 0) {
          alternatives.add(Direction.west);
        } else {
          alternatives.add(Direction.east);
        }
        break;
      case Direction.east:
      case Direction.west:
        // Primary is horizontal, try vertical alternatives
        if (dz > 0) {
          alternatives.add(Direction.south);
        } else if (dz < 0) {
          alternatives.add(Direction.north);
        }
        // Add the opposite vertical direction as backup
        if (dz >= 0) {
          alternatives.add(Direction.north);
        } else {
          alternatives.add(Direction.south);
        }
        break;
    }

    // Remove duplicates while preserving order
    final uniqueAlternatives = <Direction>[];
    for (final direction in alternatives) {
      if (!uniqueAlternatives.contains(direction)) {
        uniqueAlternatives.add(direction);
      }
    }

    return uniqueAlternatives;
  }

  /// Attempts to move ally in the specified direction
  static bool _attemptMove(
    AllyCharacter ally,
    Direction direction,
    TileMap tileMap,
  ) {
    final newPosition = _getNewPosition(ally.position, direction);

    // Check if the new position is valid and walkable
    if (!tileMap.isWalkable(newPosition)) {
      return false;
    }

    // Perform the movement
    final success = ally.moveTo(newPosition);
    if (success) {
      ally.setActive(); // Ally is moving, not idle
      ally.movementCooldown = AllyCharacter.maxMovementCooldown;
    }

    return success;
  }

  /// Gets the new position based on direction
  static Position _getNewPosition(Position current, Direction direction) {
    switch (direction) {
      case Direction.north:
        return current.add(0, -1);
      case Direction.south:
        return current.add(0, 1);
      case Direction.west:
        return current.add(-1, 0);
      case Direction.east:
        return current.add(1, 0);
    }
  }

  /// Checks if an ally should engage in combat with nearby enemies
  static bool shouldEngageInCombat(
    AllyCharacter ally,
    List<EnemyCharacter> hostileEnemies,
  ) {
    if (!ally.isAlive || ally.isSatisfied) {
      return false;
    }

    final nearbyEnemies = _findNearbyHostileEnemies(ally, hostileEnemies);
    return nearbyEnemies.isNotEmpty;
  }

  /// Gets the best target enemy for an ally to engage
  static EnemyCharacter? getBestCombatTarget(
    AllyCharacter ally,
    List<EnemyCharacter> hostileEnemies,
  ) {
    final nearbyEnemies = _findNearbyHostileEnemies(ally, hostileEnemies);

    if (nearbyEnemies.isEmpty) {
      return null;
    }

    // Prioritize closest enemy
    return nearbyEnemies.reduce(
      (a, b) =>
          ally.position.distanceTo(a.position) <
              ally.position.distanceTo(b.position)
          ? a
          : b,
    );
  }

  /// Calculates combat effectiveness of an ally against an enemy
  static double calculateCombatEffectiveness(
    AllyCharacter ally,
    EnemyCharacter enemy,
  ) {
    if (!ally.isAlive || !enemy.isAlive) {
      return 0.0;
    }

    // Base effectiveness based on health ratio
    final allyHealthRatio = ally.healthPercentage;
    final enemyHealthRatio = enemy.healthPercentage;

    // Factor in combat strength
    final strengthRatio = ally.effectiveCombatStrength / 10.0; // Normalize

    // Factor in satisfaction (higher satisfaction = better performance)
    final satisfactionBonus = ally.satisfactionPercentage * 0.2;

    // Calculate overall effectiveness
    final effectiveness =
        (allyHealthRatio * strengthRatio + satisfactionBonus) /
        (enemyHealthRatio + 0.1); // Avoid division by zero

    return effectiveness.clamp(0.0, 2.0);
  }

  /// Gets AI statistics for debugging and monitoring
  static AllyAIStats getAIStats(List<AllyCharacter> allies) {
    final followingCount = allies
        .where((a) => a.state == AllyState.following)
        .length;
    final combatCount = allies.where((a) => a.state == AllyState.combat).length;
    final satisfiedCount = allies
        .where((a) => a.state == AllyState.satisfied)
        .length;

    final averageHealth = allies.isEmpty
        ? 0.0
        : allies.map((a) => a.healthPercentage).reduce((a, b) => a + b) /
              allies.length;

    final averageSatisfaction = allies.isEmpty
        ? 0.0
        : allies.map((a) => a.satisfactionPercentage).reduce((a, b) => a + b) /
              allies.length;

    return AllyAIStats(
      totalAllies: allies.length,
      followingAllies: followingCount,
      combatAllies: combatCount,
      satisfiedAllies: satisfiedCount,
      averageHealth: averageHealth,
      averageSatisfaction: averageSatisfaction,
    );
  }
}

/// Direction enumeration for movement
enum Direction {
  north,
  south,
  east,
  west;

  String get displayName {
    switch (this) {
      case Direction.north:
        return 'North';
      case Direction.south:
        return 'South';
      case Direction.east:
        return 'East';
      case Direction.west:
        return 'West';
    }
  }
}

/// Statistics about ally AI behavior
class AllyAIStats {
  final int totalAllies;
  final int followingAllies;
  final int combatAllies;
  final int satisfiedAllies;
  final double averageHealth;
  final double averageSatisfaction;

  AllyAIStats({
    required this.totalAllies,
    required this.followingAllies,
    required this.combatAllies,
    required this.satisfiedAllies,
    required this.averageHealth,
    required this.averageSatisfaction,
  });

  /// Gets the percentage of allies in combat
  double get combatPercentage =>
      totalAllies > 0 ? combatAllies / totalAllies : 0.0;

  /// Gets the percentage of allies following
  double get followingPercentage =>
      totalAllies > 0 ? followingAllies / totalAllies : 0.0;

  /// Gets the percentage of satisfied allies
  double get satisfiedPercentage =>
      totalAllies > 0 ? satisfiedAllies / totalAllies : 0.0;

  @override
  String toString() {
    return 'AllyAIStats(Total: $totalAllies, Following: $followingAllies, '
        'Combat: $combatAllies, Satisfied: $satisfiedAllies, '
        'Avg Health: ${(averageHealth * 100).toStringAsFixed(1)}%, '
        'Avg Satisfaction: ${(averageSatisfaction * 100).toStringAsFixed(1)}%)';
  }
}
