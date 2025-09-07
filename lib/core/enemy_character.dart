import 'dart:math';

import 'package:flutter/foundation.dart';

import 'character.dart';
import 'position.dart';
import 'tile_map.dart';
import 'ghost_character.dart';
import 'enemy_spawner.dart';

/// Represents an enemy character with AI behavior
class EnemyCharacter extends Character {
  /// The current state of the enemy
  EnemyState state;

  /// Radius within which the enemy becomes active
  final int activationRadius;

  /// Whether the enemy is currently within proximity activation range
  bool isProximityActive;

  /// The enemy's AI behavior type
  final EnemyAIType aiType;

  /// Last known position of the player (for AI tracking)
  Position? lastKnownPlayerPosition;

  /// Movement cooldown to prevent too frequent movement
  int movementCooldown;

  /// Current facing direction (for animation and visual feedback)
  Direction _facingDirection = Direction.south;

  /// Maximum movement cooldown (in game ticks)
  static const int maxMovementCooldown = 3;

  /// Base combat strength for this enemy
  int? baseCombatStrength;

  /// Random number generator for AI decisions
  static final Random _random = Random();

  EnemyCharacter({
    required super.id,
    required super.position,
    required super.modelPath,
    super.health = 50,
    super.maxHealth = 50,
    this.state = EnemyState.hostile,
    this.activationRadius = 8,
    this.isProximityActive = false,
    this.aiType = EnemyAIType.wanderer,
    this.movementCooldown = 0,
    this.baseCombatStrength,
  }) : super(
         isActive: false, // Enemies start inactive until proximity activated
         canMove: true,
         isIdle: true,
       ) {
    // Set default combat strength if not provided
    baseCombatStrength ??= _getDefaultCombatStrength();
  }

  /// Factory constructor for creating enemies with human models
  factory EnemyCharacter.human({
    required String id,
    required Position position,
    required HumanModelType modelType,
    int health = 50,
    int maxHealth = 50,
    EnemyState state = EnemyState.hostile,
    int activationRadius = 8,
    EnemyAIType aiType = EnemyAIType.wanderer,
  }) {
    return EnemyCharacter(
      id: id,
      position: position,
      modelPath: modelType.modelPath,
      health: health,
      maxHealth: maxHealth,
      state: state,
      activationRadius: activationRadius,
      aiType: aiType,
    );
  }

  /// Factory constructor for creating enemies with monster models
  factory EnemyCharacter.monster({
    required String id,
    required Position position,
    required MonsterModelType modelType,
    int health = 75,
    int maxHealth = 75,
    EnemyState state = EnemyState.hostile,
    int activationRadius = 10,
    EnemyAIType aiType = EnemyAIType.aggressive,
  }) {
    return EnemyCharacter(
      id: id,
      position: position,
      modelPath: modelType.modelPath,
      health: health,
      maxHealth: maxHealth,
      state: state,
      activationRadius: activationRadius,
      aiType: aiType,
    );
  }

  /// Gets the enemy type based on the model path
  EnemyType get enemyType {
    if (modelPath.contains('character-male') ||
        modelPath.contains('character-female')) {
      return EnemyType.human;
    } else {
      return EnemyType.monster;
    }
  }

  /// Gets default combat strength based on enemy type
  int _getDefaultCombatStrength() {
    final enemyType = this.enemyType;
    switch (enemyType) {
      case EnemyType.human:
        return 15; // Humans are weaker
      case EnemyType.monster:
        return 25; // Monsters are stronger
    }
  }

  /// Attacks the player and returns damage dealt
  int attackPlayer(GhostCharacter player) {
    // Face the player when attacking
    final direction = _getDirectionTowards(player.position);
    if (direction != null) {
      _facingDirection = direction;
    }

    final combatStrength = baseCombatStrength ?? _getDefaultCombatStrength();
    final baseDamage = (combatStrength * 0.6).round();
    final randomBonus =
        (combatStrength * 0.4 * (DateTime.now().millisecond / 1000)).round();
    final totalDamage = baseDamage + randomBonus;

    debugPrint('EnemyCharacter: $id attacks player for $totalDamage damage');

    return totalDamage;
  }

  /// Updates the enemy's AI behavior (called each player turn)
  void updateAI(GhostCharacter player, TileMap tileMap) {
    final distance = position.distanceTo(player.position);

    // Debug AI processing (only for interesting cases)
    if (isProximityActive && distance <= 5) {
      debugPrint(
        'EnemyCharacter: $id turn - Active: $isActive, Proximity: $isProximityActive, '
        'State: $state, Cooldown: $movementCooldown, Distance: $distance',
      );
    }

    // Only process AI if the enemy is proximity active
    if (!isProximityActive || !isActive) {
      setIdle();
      return;
    }

    // Update movement cooldown
    if (movementCooldown > 0) {
      movementCooldown--;
      debugPrint('EnemyCharacter: $id waiting (cooldown: $movementCooldown)');
      return;
    }

    // Update last known player position if player is visible
    if (_canSeePlayer(player, tileMap)) {
      lastKnownPlayerPosition = player.position;
    }

    // Execute AI behavior based on state and type
    switch (state) {
      case EnemyState.hostile:
        _executeHostileAI(player, tileMap);
        break;
      case EnemyState.ally:
        _executeAllyAI(player, tileMap);
        break;
      case EnemyState.satisfied:
        // Satisfied enemies don't move or act
        setIdle();
        break;
    }
  }

  /// Checks if the enemy can see the player (simple line of sight)
  bool _canSeePlayer(GhostCharacter player, TileMap tileMap) {
    final distance = position.distanceTo(player.position);
    if (distance > activationRadius) return false;

    // Simple line of sight check - if player is adjacent, always visible
    if (distance <= 1) return true;

    // For longer distances, check if there's a clear path
    // This is a simplified implementation - a full line of sight would use Bresenham's algorithm
    return distance <= 3; // Simplified: can see within 3 tiles
  }

  /// Executes hostile AI behavior
  void _executeHostileAI(GhostCharacter player, TileMap tileMap) {
    switch (aiType) {
      case EnemyAIType.aggressive:
        _moveTowardsPlayer(player, tileMap);
        break;
      case EnemyAIType.wanderer:
        _wanderRandomly(tileMap, player: player);
        break;
      case EnemyAIType.guard:
        _guardBehavior(player, tileMap);
        break;
    }
  }

  /// Executes ally AI behavior
  void _executeAllyAI(GhostCharacter player, TileMap tileMap) {
    // Allies follow the player and attack hostile enemies
    final distanceToPlayer = position.distanceTo(player.position);

    if (distanceToPlayer > 2) {
      // Follow player if too far away
      _moveTowardsPlayer(player, tileMap);
    } else if (distanceToPlayer == 1) {
      // Stay close but not on top of player
      setIdle();
    } else {
      // Look for hostile enemies to attack
      // This will be expanded when combat system is implemented
      setIdle();
    }
  }

  /// Moves the enemy towards the player's position
  void _moveTowardsPlayer(GhostCharacter player, TileMap tileMap) {
    final targetPosition = lastKnownPlayerPosition ?? player.position;
    final direction = _getDirectionTowards(targetPosition);

    if (direction != null) {
      _attemptMove(direction, tileMap, player: player);
    } else {
      // If no direct path, try random movement
      _wanderRandomly(tileMap, player: player);
    }
  }

  /// Makes the enemy wander randomly
  void _wanderRandomly(TileMap tileMap, {GhostCharacter? player}) {
    final directions = Direction.values;
    final shuffledDirections = List<Direction>.from(directions)
      ..shuffle(_random);

    for (final direction in shuffledDirections) {
      if (_attemptMove(direction, tileMap, player: player)) {
        break; // Successfully moved (facing direction updated in _attemptMove)
      }
    }
  }

  /// Guard behavior - stay in place unless player gets too close
  void _guardBehavior(GhostCharacter player, TileMap tileMap) {
    final distanceToPlayer = position.distanceTo(player.position);

    if (distanceToPlayer <= 2) {
      // Player is too close, move towards them
      _moveTowardsPlayer(player, tileMap);
    } else {
      // Stay in place
      setIdle();
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
  bool _attemptMove(
    Direction direction,
    TileMap tileMap, {
    GhostCharacter? player,
  }) {
    final newPosition = _getNewPosition(direction);

    // Check if the new position would overlap with player
    if (player != null && newPosition == player.position) {
      debugPrint(
        'EnemyCharacter: $id cannot move to $newPosition - player is there',
      );
      return false;
    }

    // Check if the new position is valid and walkable
    if (!tileMap.isWalkable(newPosition)) {
      return false;
    }

    // Perform the movement
    final success = moveTo(newPosition);
    if (success) {
      _facingDirection = direction; // Update facing direction when moving successfully
      setActive(); // Enemy is moving, not idle
      movementCooldown = maxMovementCooldown;
      debugPrint('EnemyCharacter: $id moved to $newPosition');
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

  /// Activates the enemy when player is within range
  void activate() {
    isProximityActive = true;
    isActive = true;
  }

  /// Deactivates the enemy when player is out of range
  void deactivate() {
    isProximityActive = false;
    isActive = false;
    setIdle();
  }

  /// Converts the enemy to an ally state
  void convertToAlly() {
    state = EnemyState.ally;
    // Allies might have different AI behavior
  }

  /// Converts the enemy to satisfied state (will be removed from game)
  void setSatisfied() {
    state = EnemyState.satisfied;
    isActive = false;
    setIdle();
  }

  /// Returns true if the enemy is hostile
  bool get isHostile => state == EnemyState.hostile;

  /// Returns true if the enemy is an ally
  bool get isAlly => state == EnemyState.ally;

  /// Returns true if the enemy is satisfied
  bool get isSatisfied => state == EnemyState.satisfied;

  /// Gets the current facing direction for animation purposes
  Direction get facingDirection => _facingDirection;

  @override
  String toString() {
    return 'EnemyCharacter($id) at $position [State: ${state.name}, '
        'Health: $health/$maxHealth, Active: $isProximityActive]';
  }
}

/// Represents the different states an enemy can be in
enum EnemyState {
  hostile,
  ally,
  satisfied;

  String get displayName {
    switch (this) {
      case EnemyState.hostile:
        return 'Hostile';
      case EnemyState.ally:
        return 'Ally';
      case EnemyState.satisfied:
        return 'Satisfied';
    }
  }
}

/// Represents different AI behavior types
enum EnemyAIType {
  aggressive, // Actively seeks and moves towards player
  wanderer, // Moves randomly, may notice player
  guard; // Stays in place unless player gets close

  String get displayName {
    switch (this) {
      case EnemyAIType.aggressive:
        return 'Aggressive';
      case EnemyAIType.wanderer:
        return 'Wanderer';
      case EnemyAIType.guard:
        return 'Guard';
    }
  }
}

/// Available human character models
enum HumanModelType {
  femaleA('assets/characters/character-female-a.obj'),
  femaleB('assets/characters/character-female-b.obj'),
  femaleC('assets/characters/character-female-c.obj'),
  femaleD('assets/characters/character-female-d.obj'),
  femaleE('assets/characters/character-female-e.obj'),
  femaleF('assets/characters/character-female-f.obj'),
  maleA('assets/characters/character-male-a.obj'),
  maleB('assets/characters/character-male-b.obj'),
  maleC('assets/characters/character-male-c.obj'),
  maleD('assets/characters/character-male-d.obj'),
  maleE('assets/characters/character-male-e.obj'),
  maleF('assets/characters/character-male-f.obj');

  const HumanModelType(this.modelPath);
  final String modelPath;

  /// Gets a random human model type
  static HumanModelType random() {
    final values = HumanModelType.values;
    return values[Random().nextInt(values.length)];
  }
}

/// Available monster character models
enum MonsterModelType {
  skeleton('assets/graveyard/character-skeleton.obj'),
  vampire('assets/graveyard/character-vampire.obj'),
  zombie('assets/graveyard/character-zombie.obj'),
  digger('assets/graveyard/character-digger.obj');

  const MonsterModelType(this.modelPath);
  final String modelPath;

  /// Gets a random monster model type
  static MonsterModelType random() {
    final values = MonsterModelType.values;
    return values[Random().nextInt(values.length)];
  }
}
