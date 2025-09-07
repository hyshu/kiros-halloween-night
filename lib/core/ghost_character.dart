import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'character.dart';
import 'position.dart';
import 'tile_map.dart';
import 'tile_type.dart';
import 'inventory.dart';
import 'candy_item.dart';
import 'ally_manager.dart';
import 'ally_character.dart';
import 'enemy_character.dart';
import 'enemy_manager.dart';
import 'player_combat_result.dart';

/// Represents the player-controlled ghost character Kiro
class GhostCharacter extends Character {
  /// Abilities granted by collected candy
  final Map<String, dynamic> abilities = {};

  /// Player's candy inventory
  final Inventory inventory;

  /// Ally manager for handling converted enemies
  final AllyManager allyManager;

  /// Movement input state
  bool _isProcessingInput = false;

  /// Last movement direction for animation purposes
  Direction? lastMovementDirection;

  /// Player's base combat strength
  int baseCombatStrength;

  /// Combat strength bonus from candies and abilities
  int combatStrengthBonus;

  /// Number of enemies defeated by player
  int enemiesDefeated;

  /// Whether player is currently in combat
  bool isInCombat;

  GhostCharacter({
    required super.id,
    required super.position,
    super.health = 100,
    super.maxHealth = 100,
    this.baseCombatStrength = 20,
    this.combatStrengthBonus = 0,
    this.enemiesDefeated = 0,
    this.isInCombat = false,
    Inventory? inventory,
    AllyManager? allyManager,
  }) : inventory = inventory ?? Inventory(),
       allyManager = allyManager ?? AllyManager(),
       super(
         modelPath: 'assets/graveyard/character-ghost.obj',
         isActive: true,
         canMove: true,
         isIdle: true,
       ) {
    // Set this character as the player for the ally manager
    this.allyManager.setPlayer(this);
  }

  /// Handles keyboard input for movement and combat
  /// Returns true if the key was recognized (regardless of action success)
  bool handleInput(
    LogicalKeyboardKey key,
    TileMap? tileMap, {
    EnemyManager? enemyManager,
    Function()? onInventoryToggle,
    Function()? onGiftToggle,
  }) {
    if (_isProcessingInput || !canMove) return false;

    // Handle inventory toggle
    if (key == LogicalKeyboardKey.keyI) {
      onInventoryToggle?.call();
      return true;
    }
    
    // Handle gift toggle (G key)
    if (key == LogicalKeyboardKey.keyG) {
      onGiftToggle?.call();
      return true;
    }

    Direction? direction;
    switch (key) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        direction = Direction.north;
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        direction = Direction.south;
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        direction = Direction.west;
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        direction = Direction.east;
        break;
      default:
        return false; // Key not handled
    }

    // Key was recognized, check for enemy in that direction
    final targetPosition = _getNewPosition(direction);

    // Check if there's an enemy at target position
    if (enemyManager != null) {
      final enemiesAtTarget = enemyManager.getEnemiesAt(targetPosition);
      if (enemiesAtTarget.isNotEmpty) {
        // Attack instead of move
        _performAttackAtPosition(targetPosition, enemiesAtTarget);
        return true; // Key was handled as attack
      }
    }

    // No enemy at target, attempt normal movement
    attemptMove(direction, tileMap, enemyManager: enemyManager);
    return true; // Key was handled, regardless of movement success
  }

  /// Attempts to move in the specified direction
  /// Returns true if the move was successful
  bool attemptMove(
    Direction direction,
    TileMap? tileMap, {
    EnemyManager? enemyManager,
  }) {
    if (_isProcessingInput || !canMove) return false;

    _isProcessingInput = true;

    try {
      final newPosition = _getNewPosition(direction);

      // Check for enemies at target position (prevent overlap)
      if (enemyManager != null) {
        final enemiesAtTarget = enemyManager.getEnemiesAt(newPosition);
        if (enemiesAtTarget.isNotEmpty) {
          setIdle();
          return false; // Cannot move into enemy position
        }
      }

      // Validate movement with tile map if available
      if (tileMap != null) {
        if (!_canMoveTo(newPosition, tileMap)) {
          setIdle();
          return false;
        }
      }

      // Perform the movement
      final success = moveTo(newPosition);
      if (success) {
        lastMovementDirection = direction;
        setActive(); // Character is moving, not idle
        _moveAllies(direction, tileMap);
      } else {
        setIdle();
      }

      return success;
    } finally {
      _isProcessingInput = false;
    }
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

  /// Checks if movement to the new position is valid
  bool _canMoveTo(Position newPosition, TileMap tileMap) {
    // Check bounds
    if (!tileMap.isValidPosition(newPosition)) {
      return false;
    }

    // Check tile type - can't move through walls or obstacles
    final tileType = tileMap.getTileAt(newPosition);
    switch (tileType) {
      case TileType.wall:
      case TileType.obstacle:
        return false;
      case TileType.floor:
      case TileType.candy:
        return true;
    }
  }

  /// Moves all allied characters to follow Kiro
  void _moveAllies(Direction direction, TileMap? tileMap) {
    // Allies are now managed by the AllyManager
    // Their movement is handled in their own AI update cycle
    // This method is kept for compatibility but allies move independently
  }

  /// Adds an ability from collected candy
  void addAbility(String abilityName, dynamic value) {
    abilities[abilityName] = value;

    // Apply ability effects
    switch (abilityName) {
      case 'healthBoost':
        if (value is int) {
          heal(value);
        }
        break;
      case 'speedIncrease':
        // Speed increase would be handled in movement timing
        break;
      case 'maxHealthIncrease':
        if (value is int) {
          // This would require modifying the base Character class
          // For now, just store the ability
        }
        break;
    }
  }

  /// Removes an ability (when candy effect expires or is consumed)
  void removeAbility(String abilityName) {
    abilities.remove(abilityName);
  }

  /// Gets the current value of an ability
  T? getAbility<T>(String abilityName) {
    final value = abilities[abilityName];
    return value is T ? value : null;
  }

  /// Checks if the character has a specific ability
  bool hasAbility(String abilityName) {
    return abilities.containsKey(abilityName);
  }

  /// Collects a candy item and adds it to inventory
  /// Returns true if successful, false if inventory is full
  bool collectCandy(CandyItem candy) {
    return inventory.addCandy(candy);
  }

  /// Uses a candy item from inventory and applies its effects
  /// Returns true if successful, false if candy not found
  bool useCandy(String candyId) {
    final candy = inventory.getCandyById(candyId);
    if (candy == null) return false;

    // Store candy properties before removal
    final effect = candy.effect;
    final value = candy.value;

    // Use the candy (this will handle temporary effects and remove from inventory)
    final success = inventory.useCandy(candyId);

    if (success) {
      // Apply immediate effects after removal
      switch (effect) {
        case CandyEffect.healthBoost:
          heal(value);
          break;

        case CandyEffect.maxHealthIncrease:
          // Note: This would require modifying the base Character class
          // For now, we'll store it as an ability
          addAbility(
            'maxHealthBonus',
            (getAbility<int>('maxHealthBonus') ?? 0) + value,
          );
          break;

        case CandyEffect.speedIncrease:
        case CandyEffect.allyStrength:
        case CandyEffect.specialAbility:
        case CandyEffect.statModification:
          // These are handled by the inventory's temporary effect system
          break;
      }
    }

    return success;
  }

  /// Gets available candy for gifting to enemies
  List<CandyItem> getAvailableCandyForGifting() {
    return inventory.getAvailableForGifting();
  }

  /// Gives a candy item to an enemy (removes from inventory)
  /// Returns the candy item if successful, null if not found
  CandyItem? giveCandy(String candyId) {
    return inventory.removeCandyById(candyId);
  }

  /// Updates temporary effects from candy (call each turn)
  void updateCandyEffects() {
    inventory.updateTemporaryEffects();

    // Apply ally combat bonuses from candy effects
    final allyBonus = effectiveAllyDamageBonus;
    if (allyBonus > 0) {
      allyManager.applyGlobalCombatBonus(allyBonus);
    }
  }

  /// Gets the effective speed multiplier including candy effects
  double get effectiveSpeedMultiplier {
    final baseSpeed = 1.0;
    final speedBonus = inventory.getTotalAbilityModification('speedMultiplier');
    return baseSpeed + speedBonus;
  }

  /// Gets the effective ally damage bonus from candy effects
  int get effectiveAllyDamageBonus {
    return inventory.getTotalAbilityModification('allyDamageBonus').round();
  }

  /// Checks if the character has wall vision from candy effects
  bool get hasWallVision {
    return inventory.hasActiveAbility('wallVision');
  }

  /// Checks if the character can freeze enemies from candy effects
  bool get canFreezeEnemies {
    return inventory.hasActiveAbility('freezeEnemies');
  }

  /// Gets the player's total combat strength
  int get effectiveCombatStrength {
    final candyBonus = inventory
        .getTotalAbilityModification('combatStrength')
        .round();
    return baseCombatStrength + combatStrengthBonus + candyBonus;
  }

  /// Attacks an enemy and returns combat result
  PlayerCombatResult attackEnemy(EnemyCharacter enemy) {
    isInCombat = true;
    final playerStrength = effectiveCombatStrength;

    // Calculate damage with some randomness
    final baseDamage = (playerStrength * 0.8).round();
    final randomBonus =
        (playerStrength * 0.4 * (DateTime.now().millisecond / 1000)).round();
    final totalDamage = baseDamage + randomBonus;

    // Apply damage to enemy
    final wasAlive = enemy.isAlive;
    enemy.takeDamage(totalDamage);

    final result = PlayerCombatResult(
      playerDamageDealt: totalDamage,
      enemyDefeated: wasAlive && !enemy.isAlive,
      playerHealth: health,
      enemyHealth: enemy.health,
      combatDescription: _getCombatDescription(totalDamage, enemy.isAlive),
    );

    // Update statistics
    if (result.enemyDefeated) {
      enemiesDefeated++;
      // Gain some health for defeating enemy (ghost power)
      final healthGain = (maxHealth * 0.1).round();
      heal(healthGain);
    }

    isInCombat = false;
    return result;
  }

  /// Takes damage from enemy attack
  void takeDamageFromEnemy(int damage, EnemyCharacter attacker) {
    takeDamage(damage);

    // Apply defensive abilities from candies
    if (inventory.hasActiveAbility('damageReduction')) {
      final reduction = inventory.getTotalAbilityModification(
        'damageReduction',
      );
      final reducedDamage = (damage * (1.0 - reduction)).round();
      heal(damage - reducedDamage); // Restore some health due to reduction
    }
  }

  /// Increases combat strength temporarily
  void addCombatStrengthBonus(int bonus) {
    combatStrengthBonus += bonus;
  }

  /// Removes combat strength bonus
  void removeCombatStrengthBonus(int bonus) {
    combatStrengthBonus = (combatStrengthBonus - bonus)
        .clamp(0, double.infinity)
        .toInt();
  }

  /// Performs an attack on enemies at a specific position
  void _performAttackAtPosition(
    Position targetPosition,
    List<EnemyCharacter> enemies,
  ) {
    debugPrint(
      'GhostCharacter: Attacking ${enemies.length} enemies at $targetPosition',
    );

    // Attack the first enemy at the position
    if (enemies.isNotEmpty) {
      final enemy = enemies.first;
      final result = attackEnemy(enemy);

      // Store the result for GameLoopManager to process
      _lastAttackResult = result;

      debugPrint('GhostCharacter: ${result.combatDescription}');

      // Player doesn't move, just attacks
      setIdle();
    }
  }

  /// Last attack result for GameLoopManager to access
  PlayerCombatResult? _lastAttackResult;

  /// Gets and clears the last attack result
  PlayerCombatResult? consumeLastAttackResult() {
    final result = _lastAttackResult;
    _lastAttackResult = null;
    return result;
  }

  /// Gets combat description for feedback
  String _getCombatDescription(int damage, bool enemyStillAlive) {
    if (enemyStillAlive) {
      if (damage >= 30) {
        return 'Kiro unleashes a powerful spectral attack! ($damage damage)';
      } else if (damage >= 20) {
        return 'Kiro strikes with ghostly force! ($damage damage)';
      } else {
        return 'Kiro attacks with ethereal energy ($damage damage)';
      }
    } else {
      return 'Kiro\'s spectral power banishes the enemy! ($damage damage - DEFEATED!)';
    }
  }

  /// Gets the current luck bonus from candy effects
  int get luckBonus {
    return inventory.getTotalAbilityModification('luck').round();
  }

  /// Sets the character to idle state with proper animation state
  @override
  void setIdle() {
    super.setIdle();
    lastMovementDirection = null;
  }

  /// Gets the current facing direction for animation purposes
  Direction? get facingDirection => lastMovementDirection;

  /// Returns true if the character is currently moving
  bool get isMoving => !isIdle && _isProcessingInput;

  /// Gets the number of active allies
  int get allyCount => allyManager.count;

  /// Gets all active allies
  List<AllyCharacter> get allies => allyManager.allies;

  @override
  String toString() =>
      'GhostCharacter($id) at $position [Health: $health/$maxHealth, Inventory: ${inventory.count} items, Allies: ${allyManager.count}, Abilities: ${abilities.keys.join(', ')}]';
}

/// Represents movement directions
enum Direction {
  north,
  south,
  east,
  west;

  /// Returns the opposite direction
  Direction get opposite {
    switch (this) {
      case Direction.north:
        return Direction.south;
      case Direction.south:
        return Direction.north;
      case Direction.east:
        return Direction.west;
      case Direction.west:
        return Direction.east;
    }
  }

  /// Returns a human-readable name
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
