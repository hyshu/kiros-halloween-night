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
    this.preferredFollowDistance = 1,
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
  Future<void> updateAI(
    TileMap tileMap,
    List<EnemyCharacter> hostileEnemies, {
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
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
        await _executeFollowingBehavior(
          tileMap,
          hostileEnemies,
          onAnimateMovement: onAnimateMovement,
        );
        break;
      case AllyState.combat:
        await _executeCombatBehavior(
          tileMap,
          hostileEnemies,
          onAnimateMovement: onAnimateMovement,
        );
        break;
      case AllyState.satisfied:
        // Satisfied allies don't move or act
        setIdle();
        break;
    }
  }

  /// Executes following behavior
  Future<void> _executeFollowingBehavior(
    TileMap tileMap,
    List<EnemyCharacter> hostileEnemies, {
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    if (_followTarget == null) {
      setIdle();
      return;
    }

    // Check for nearby hostile enemies first
    final nearbyEnemies = _getNearbyHostileEnemies(hostileEnemies);
    if (nearbyEnemies.isNotEmpty) {
      state = AllyState.combat;
      await _executeCombatBehavior(
        tileMap,
        hostileEnemies,
        onAnimateMovement: onAnimateMovement,
      );
      return;
    }

    // Follow the player
    final distanceToPlayer = position.distanceTo(_followTarget!.position);

    if (distanceToPlayer > 1) {
      // Distance > 1: Always rush toward player
      await _moveTowardsTarget(
        _followTarget!.position,
        tileMap,
        onAnimateMovement: onAnimateMovement,
      );
    } else {
      // Distance = 1: At perfect distance, stay put or move randomly
      if (_random.nextDouble() < 0.3) {
        // 30% chance to move randomly
        await _wanderRandomly(tileMap, onAnimateMovement: onAnimateMovement);
      } else {
        setIdle();
      }
    }
  }

  /// Executes combat behavior
  Future<void> _executeCombatBehavior(
    TileMap tileMap,
    List<EnemyCharacter> hostileEnemies, {
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final nearbyEnemies = _getNearbyHostileEnemies(hostileEnemies);

    if (nearbyEnemies.isEmpty) {
      // No enemies nearby, return to following
      state = AllyState.following;
      await _executeFollowingBehavior(
        tileMap,
        hostileEnemies,
        onAnimateMovement: onAnimateMovement,
      );
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
    await _moveTowardsTarget(
      closestEnemy.position,
      tileMap,
      onAnimateMovement: onAnimateMovement,
    );
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

  /// Moves towards a target position with obstacle avoidance
  Future<void> _moveTowardsTarget(
    Position target,
    TileMap tileMap, {
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final primaryDirection = _getDirectionTowards(target);

    if (primaryDirection != null) {
      // Try primary direction first
      if (await _attemptMove(
        primaryDirection,
        tileMap,
        onAnimateMovement: onAnimateMovement,
      )) {
        return; // Successfully moved in primary direction
      }

      // Primary direction blocked, try alternative paths
      final alternativeDirections = _getAlternativeDirections(primaryDirection, target);

      for (final direction in alternativeDirections) {
        if (await _attemptMove(
          direction,
          tileMap,
          onAnimateMovement: onAnimateMovement,
        )) {
          return; // Successfully moved in alternative direction
        }
      }
    }

    // If no direct path available, try random movement as last resort
    await _wanderRandomly(tileMap, onAnimateMovement: onAnimateMovement);
  }

  /// Makes the ally wander randomly
  Future<void> _wanderRandomly(
    TileMap tileMap, {
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final directions = Direction.values;
    final shuffledDirections = List<Direction>.from(directions)
      ..shuffle(_random);

    for (final direction in shuffledDirections) {
      if (await _attemptMove(
        direction,
        tileMap,
        onAnimateMovement: onAnimateMovement,
      )) {
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

  /// Gets alternative directions to try when primary direction is blocked
  List<Direction> _getAlternativeDirections(Direction primaryDirection, Position target) {
    final dx = target.x - position.x;
    final dz = target.z - position.z;
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

  /// Attempts to move in the specified direction
  Future<bool> _attemptMove(
    Direction direction,
    TileMap tileMap, {
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final newPosition = _getNewPosition(direction);

    // Check if the new position is valid and walkable
    if (!tileMap.isWalkable(newPosition)) {
      return false;
    }

    // Store previous position for animation
    final fromPosition = position;

    // Perform the movement (update game logic position immediately)
    final success = moveTo(newPosition);

    if (success) {
      _facingDirection =
          direction; // Update facing direction when moving successfully
      setActive(); // Ally is moving, not idle

      // Trigger animation if callback provided
      if (onAnimateMovement != null) {
        onAnimateMovement(id, fromPosition, newPosition);
      }
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
