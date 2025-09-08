import 'dart:math';
import 'character.dart';
import 'position.dart';
import 'tile_map.dart';
import 'ghost_character.dart';
import 'enemy_character.dart';
import 'enemy_spawner.dart';

/// Represents an allied character that follows Kiro and fights hostile enemies
class AllyCharacter extends Character {
  /// The original enemy character this ally was converted from
  final EnemyCharacter originalEnemy;

  /// The player character this ally follows
  GhostCharacter? _followTarget;

  /// Preferred distance to maintain from the follow target
  final int preferredFollowDistance;

  /// Maximum distance before ally tries to catch up
  final int maxFollowDistance;

  /// Current ally state
  AllyState state;

  /// Movement cooldown to prevent too frequent movement
  int movementCooldown;

  /// Maximum movement cooldown (in game ticks)
  static const int maxMovementCooldown =
      2; // Allies move slightly faster than enemies

  /// Combat strength bonus from candy effects
  int combatStrengthBonus;

  /// Current facing direction (for animation and visual feedback)
  Direction _facingDirection = Direction.south;

  /// Satisfaction level (decreases over time or when taking damage)
  int satisfaction;

  /// Maximum satisfaction level
  final int maxSatisfaction;

  /// Random number generator for AI decisions
  static final Random _random = Random();

  AllyCharacter({
    required this.originalEnemy,
    this.preferredFollowDistance = 2,
    this.maxFollowDistance = 5,
    this.state = AllyState.following,
    this.movementCooldown = 0,
    this.combatStrengthBonus = 0,
    this.satisfaction = 100,
    this.maxSatisfaction = 100,
  }) : super(
         id: '${originalEnemy.id}_ally',
         position: originalEnemy.position,
         modelPath: originalEnemy.modelPath,
         health: originalEnemy.health,
         maxHealth: originalEnemy.maxHealth,
         isActive: true,
         canMove: true,
         isIdle: false,
       );

  /// Gets the follow target (player character)
  GhostCharacter? get followTarget => _followTarget;

  /// Sets the follow target (player character)
  void setFollowTarget(GhostCharacter target) {
    _followTarget = target;
  }

  /// Updates the ally's AI behavior (called each game tick)
  void updateAI(TileMap tileMap, List<EnemyCharacter> hostileEnemies) {
    // Update satisfaction (decreases slowly over time)
    _updateSatisfaction();

    // Check if ally should become satisfied and disappear
    if (satisfaction <= 0) {
      state = AllyState.satisfied;
      return;
    }

    // Execute behavior based on current state
    switch (state) {
      case AllyState.following:
        _executeFollowingBehavior(tileMap, hostileEnemies);
        break;
      case AllyState.combat:
        _executeCombatBehavior(tileMap, hostileEnemies);
        break;
      case AllyState.satisfied:
        // Satisfied allies don't move or act
        setIdle();
        break;
    }
  }

  /// Executes following behavior
  void _executeFollowingBehavior(
    TileMap tileMap,
    List<EnemyCharacter> hostileEnemies,
  ) {
    if (_followTarget == null) {
      setIdle();
      return;
    }

    // Check for nearby hostile enemies first
    final nearbyEnemies = _getNearbyHostileEnemies(hostileEnemies);
    if (nearbyEnemies.isNotEmpty) {
      state = AllyState.combat;
      _executeCombatBehavior(tileMap, hostileEnemies);
      return;
    }

    // Follow the player
    final distanceToPlayer = position.distanceTo(_followTarget!.position);

    if (distanceToPlayer > 2) {
      // Distance > 2: Always rush toward player
      _moveTowardsTarget(_followTarget!.position, tileMap);
    } else if (distanceToPlayer < 1) {
      // Distance < 1: Stay in place (don't move away)
      setIdle();
    } else {
      // Distance 1-2: At good distance, stay put or move randomly
      if (_random.nextDouble() < 0.3) {
        // 30% chance to move randomly
        _wanderRandomly(tileMap);
      } else {
        setIdle();
      }
    }
  }

  /// Executes combat behavior
  void _executeCombatBehavior(
    TileMap tileMap,
    List<EnemyCharacter> hostileEnemies,
  ) {
    final nearbyEnemies = _getNearbyHostileEnemies(hostileEnemies);

    if (nearbyEnemies.isEmpty) {
      // No enemies nearby, return to following
      state = AllyState.following;
      _executeFollowingBehavior(tileMap, hostileEnemies);
      return;
    }

    // Find the closest enemy
    final closestEnemy = nearbyEnemies.reduce(
      (a, b) =>
          position.distanceTo(a.position) < position.distanceTo(b.position)
          ? a
          : b,
    );

    // Move towards the closest enemy
    _moveTowardsTarget(closestEnemy.position, tileMap);
  }

  /// Gets nearby hostile enemies within combat range
  List<EnemyCharacter> _getNearbyHostileEnemies(
    List<EnemyCharacter> hostileEnemies,
  ) {
    const combatRange = 4; // Range at which ally will engage enemies

    return hostileEnemies.where((enemy) {
      return enemy.isHostile &&
          enemy.isProximityActive &&
          position.distanceTo(enemy.position) <= combatRange;
    }).toList();
  }

  /// Moves towards a target position
  void _moveTowardsTarget(Position target, TileMap tileMap) {
    final direction = _getDirectionTowards(target);

    if (direction != null) {
      _attemptMove(direction, tileMap);
    } else {
      // If no direct path, try random movement
      _wanderRandomly(tileMap);
    }
  }

  /// Makes the ally wander randomly
  void _wanderRandomly(TileMap tileMap) {
    final directions = Direction.values;
    final shuffledDirections = List<Direction>.from(directions)
      ..shuffle(_random);

    for (final direction in shuffledDirections) {
      if (_attemptMove(direction, tileMap)) {
        break; // Successfully moved (facing direction updated in _attemptMove)
      }
    }
  }

  /// Gets the best direction to move towards a target position
  Direction? _getDirectionTowards(Position target) {
    final dx = target.x - position.x;
    final dz = target.z - position.z;

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

  /// Attempts to move in the specified direction
  bool _attemptMove(Direction direction, TileMap tileMap) {
    final newPosition = _getNewPosition(direction);

    // Check if the new position is valid and walkable
    if (!tileMap.isWalkable(newPosition)) {
      return false;
    }

    // Perform the movement
    final success = moveTo(newPosition);

    if (success) {
      _facingDirection =
          direction; // Update facing direction when moving successfully
      setActive(); // Ally is moving, not idle
    }

    return success;
  }

  /// Gets the new position based on direction
  Position _getNewPosition(Direction direction) {
    switch (direction) {
      case Direction.north:
        return position.add(0, -1);
      case Direction.south:
        return position.add(0, 1);
      case Direction.west:
        return position.add(-1, 0);
      case Direction.east:
        return position.add(1, 0);
    }
  }

  /// Updates satisfaction level over time
  void _updateSatisfaction() {
    // Satisfaction decreases slowly over time
    if (_random.nextDouble() < 0.02) {
      // 2% chance per tick
      satisfaction = (satisfaction - 1).clamp(0, maxSatisfaction);
    }
  }

  /// Reduces satisfaction when taking damage
  @override
  bool takeDamage(int damage) {
    final wasAlive = super.takeDamage(damage);

    // Taking damage reduces satisfaction
    satisfaction = (satisfaction - damage * 2).clamp(0, maxSatisfaction);

    // If health reaches zero, become satisfied (disappear)
    if (!wasAlive) {
      state = AllyState.satisfied;
      satisfaction = 0;
    }

    return wasAlive;
  }

  /// Increases satisfaction (when helping player or receiving benefits)
  void increaseSatisfaction(int amount) {
    satisfaction = (satisfaction + amount).clamp(0, maxSatisfaction);
  }

  /// Gets the effective combat strength including bonuses
  int get effectiveCombatStrength {
    return 10 + combatStrengthBonus; // Base strength + bonuses
  }

  /// Applies combat strength bonus from candy effects
  void applyCombatStrengthBonus(int bonus) {
    combatStrengthBonus += bonus;
  }

  /// Removes combat strength bonus (when effect expires)
  void removeCombatStrengthBonus(int bonus) {
    combatStrengthBonus = (combatStrengthBonus - bonus).clamp(0, 100);
  }

  /// Returns true if the ally is following the player
  bool get isFollowing => state == AllyState.following;

  /// Returns true if the ally is in combat
  bool get isInCombat => state == AllyState.combat;

  /// Returns true if the ally is satisfied and should be removed
  bool get isSatisfied => state == AllyState.satisfied || satisfaction <= 0;

  /// Gets the satisfaction percentage (0.0 to 1.0)
  double get satisfactionPercentage => satisfaction / maxSatisfaction;

  /// Gets the original enemy type
  EnemyType get enemyType => originalEnemy.enemyType;

  /// Gets the original enemy AI type
  EnemyAIType get originalAIType => originalEnemy.aiType;

  /// Gets the current facing direction for animation purposes
  Direction get facingDirection => _facingDirection;

  @override
  String toString() {
    return 'AllyCharacter($id) at $position [State: ${state.name}, '
        'Health: $health/$maxHealth, Satisfaction: $satisfaction/$maxSatisfaction]';
  }
}

/// Represents the different states an ally can be in
enum AllyState {
  following, // Following the player
  combat, // Engaging hostile enemies
  satisfied; // Satisfied and ready to disappear

  String get displayName {
    switch (this) {
      case AllyState.following:
        return 'Following';
      case AllyState.combat:
        return 'Combat';
      case AllyState.satisfied:
        return 'Satisfied';
    }
  }
}
