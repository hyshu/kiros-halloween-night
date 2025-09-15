import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math.dart';

import 'enemy_character.dart';
import 'ghost_character.dart';
import 'position.dart';
import 'tile_map.dart';
import 'collision_detector.dart';
import 'dialogue_manager.dart';
import '../l10n/strings.g.dart';

/// Represents the main boss character with enhanced abilities and special mechanics
class BossCharacter extends EnemyCharacter {
  /// Boss phases for different behavior patterns
  BossPhase currentPhase;

  /// Special abilities available to the boss
  final List<BossAbility> abilities;

  /// Ability cooldowns (in turns)
  final Map<BossAbility, int> abilityCooldowns = {};

  /// Whether the boss has been encountered by the player
  bool hasBeenEncountered = false;

  /// Victory state - true when boss is defeated
  bool isDefeated = false;

  /// Boss's special attack patterns
  final List<AttackPattern> attackPatterns;

  /// Current attack pattern index
  int currentAttackPatternIndex = 0;

  /// Turns since last special ability use
  int turnsSinceLastAbility = 0;

  /// Maximum range for boss special attacks
  static const int bossAttackRange = 3;

  /// Boss regeneration amount per turn
  static const int regenerationPerTurn = 5;

  /// Random number generator for boss AI
  static final Random _random = Random();

  /// Current facing direction (for animation and visual feedback)
  Direction _facingDirection = Direction.south;

  /// Dialogue manager for displaying boss ability messages
  DialogueManager? _dialogueManager;

  BossCharacter({
    required super.id,
    required super.position,
    required super.modelPath,
    super.health = 500,
    super.maxHealth = 500,
    super.state = EnemyState.hostile,
    super.activationRadius = 20,
    super.aiType = EnemyAIType.aggressive,
    this.currentPhase = BossPhase.aggressive,
    List<BossAbility>? abilities,
    List<AttackPattern>? attackPatterns,
  }) : abilities = abilities ?? _getDefaultAbilities(),
       attackPatterns = attackPatterns ?? _getDefaultAttackPatterns(),
       super(
         baseCombatStrength: 75, // 3x stronger than normal monsters
       ) {
    // Initialize ability cooldowns
    for (final ability in this.abilities) {
      abilityCooldowns[ability] = 0;
    }
  }

  /// Factory constructor for creating the main boss
  factory BossCharacter.mainBoss({
    required String id,
    required Position position,
  }) {
    return BossCharacter(
      id: id,
      position: position,
      modelPath: 'assets/graveyard/character-vampire-boss.obj',
      health: 500,
      maxHealth: 500,
      activationRadius: 25, // Boss has massive detection range
      abilities: [
        BossAbility.charge,
        BossAbility.areaAttack,
        BossAbility.regeneration,
        BossAbility.summonMinions,
      ],
      attackPatterns: [AttackPattern.directAssault, AttackPattern.circling],
    );
  }

  /// Returns the model matrix
  @override
  Matrix4 get modelMatrix {
    final worldPos = worldPosition;
    return Matrix4.identity()..translateByVector3(worldPos);
  }

  /// Boss cannot receive candy gifts
  @override
  bool canReceiveCandy() {
    return false;
  }

  /// Sets the dialogue manager for boss ability messages
  void setDialogueManager(DialogueManager? dialogueManager) {
    _dialogueManager = dialogueManager;
  }

  /// Boss-specific AI behavior that's more sophisticated than regular enemies
  @override
  Future<void> updateAI(
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    if (!isActive || isDefeated) {
      setIdle();
      return;
    }

    // Mark as encountered when player gets close
    if (!hasBeenEncountered) {
      final distance = position.distanceTo(player.position);
      if (distance <= activationRadius) {
        hasBeenEncountered = true;
        debugPrint(
          'BossCharacter: Boss $id has been encountered by the player!',
        );
      }
    }

    // Update boss phase based on health
    _updateBossPhase();

    // Decrement ability cooldowns
    _updateAbilityCooldowns();

    // Boss regeneration in tactical phase (when being strategic)
    if (currentPhase == BossPhase.tactical && health < maxHealth) {
      heal(regenerationPerTurn);
      debugPrint(
        'BossCharacter: Boss $id regenerated $regenerationPerTurn health',
      );
    }

    // Execute boss AI based on current phase
    await _executeBossAI(
      player,
      tileMap,
      collisionDetector: collisionDetector,
      onAnimateMovement: onAnimateMovement,
    );
  }

  /// Updates the boss phase based on current health percentage
  void _updateBossPhase() {
    final healthPercent = healthPercentage;
    final previousPhase = currentPhase;

    if (healthPercent > 0.75) {
      currentPhase = BossPhase.aggressive;
    } else if (healthPercent > 0.35) {
      currentPhase = BossPhase.tactical;
    } else if (healthPercent > 0.0) {
      currentPhase = BossPhase.desperate;
    } else {
      currentPhase = BossPhase.defeated;
      isDefeated = true;
    }

    if (previousPhase != currentPhase) {
      debugPrint(
        'BossCharacter: Boss $id phase changed from ${previousPhase.name} to ${currentPhase.name}',
      );
    }
  }

  /// Decrements all ability cooldowns
  void _updateAbilityCooldowns() {
    for (final ability in abilities) {
      if (abilityCooldowns[ability]! > 0) {
        abilityCooldowns[ability] = abilityCooldowns[ability]! - 1;
      }
    }
    turnsSinceLastAbility++;
  }

  /// Executes sophisticated boss AI behavior
  Future<void> _executeBossAI(
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    // Try to use special abilities first
    if (_shouldUseSpecialAbility(player)) {
      final abilityUsed = await _tryUseSpecialAbility(
        player,
        tileMap,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      );

      if (abilityUsed) {
        return; // Ability used, skip normal movement
      }
    }

    // Execute movement based on current phase and attack pattern
    switch (currentPhase) {
      case BossPhase.aggressive:
        await _executeAggressivePhase(
          player,
          tileMap,
          collisionDetector: collisionDetector,
          onAnimateMovement: onAnimateMovement,
        );
        break;

      case BossPhase.tactical:
        await _executeTacticalPhase(
          player,
          tileMap,
          collisionDetector: collisionDetector,
          onAnimateMovement: onAnimateMovement,
        );
        break;

      case BossPhase.desperate:
        await _executeDesperatePhase(
          player,
          tileMap,
          collisionDetector: collisionDetector,
          onAnimateMovement: onAnimateMovement,
        );
        break;

      case BossPhase.defeated:
        // Boss is defeated, no movement
        setIdle();
        break;
    }
  }

  /// Checks if boss should use a special ability
  bool _shouldUseSpecialAbility(GhostCharacter player) {
    // Use abilities more frequently as health decreases
    final baseChance = currentPhase == BossPhase.desperate
        ? 0.6
        : currentPhase == BossPhase.tactical
        ? 0.4
        : 0.25;

    // Increase chance if haven't used ability recently
    final timeModifier = turnsSinceLastAbility > 3 ? 0.3 : 0.0;

    final totalChance = baseChance + timeModifier;
    return _random.nextDouble() < totalChance;
  }

  /// Attempts to use a special ability
  Future<bool> _tryUseSpecialAbility(
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final availableAbilities = abilities
        .where((ability) => abilityCooldowns[ability]! <= 0)
        .toList();

    if (availableAbilities.isEmpty) return false;

    // Choose ability based on situation
    final chosenAbility = _chooseOptimalAbility(availableAbilities, player);

    if (chosenAbility != null) {
      await _useAbility(
        chosenAbility,
        player,
        tileMap,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      );
      return true;
    }

    return false;
  }

  /// Chooses the optimal ability for the current situation
  BossAbility? _chooseOptimalAbility(
    List<BossAbility> availableAbilities,
    GhostCharacter player,
  ) {
    final distance = position.distanceTo(player.position);

    // Prioritize abilities based on distance and phase
    if (distance <= 2 && availableAbilities.contains(BossAbility.areaAttack)) {
      return BossAbility.areaAttack;
    }

    if (distance > 3 && availableAbilities.contains(BossAbility.charge)) {
      return BossAbility.charge;
    }

    if (healthPercentage < 0.5 &&
        availableAbilities.contains(BossAbility.regeneration)) {
      return BossAbility.regeneration;
    }

    if (currentPhase == BossPhase.desperate &&
        availableAbilities.contains(BossAbility.summonMinions)) {
      return BossAbility.summonMinions;
    }

    // Return random available ability
    if (availableAbilities.isNotEmpty) {
      return availableAbilities[_random.nextInt(availableAbilities.length)];
    }

    return null;
  }

  /// Uses a specific boss ability
  Future<void> _useAbility(
    BossAbility ability,
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    switch (ability) {
      case BossAbility.charge:
        await _useChargeAbility(
          player,
          tileMap,
          collisionDetector,
          onAnimateMovement,
        );
        break;
      case BossAbility.areaAttack:
        await _useAreaAttackAbility(player);
        break;
      case BossAbility.regeneration:
        await _useRegenerationAbility();
        break;
      case BossAbility.summonMinions:
        await _useSummonMinionsAbility(tileMap);
        break;
    }

    // Set cooldown and reset turn counter
    abilityCooldowns[ability] = _getAbilityCooldown(ability);
    turnsSinceLastAbility = 0;

    debugPrint('BossCharacter: Boss $id used ${ability.name} ability');
  }

  /// Charge ability - boss moves multiple tiles toward player
  Future<void> _useChargeAbility(
    GhostCharacter player,
    TileMap tileMap,
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  ) async {
    // Show charge message
    _dialogueManager?.showBossAttack(t.combat.bossAbilities.charge);

    final direction = _getDirectionTowards(player.position);
    if (direction == null) return;

    // Try to move 2-3 tiles in player's direction
    final chargeDistance = _random.nextInt(2) + 2; // 2-3 tiles
    Position? targetPosition = position;

    for (int i = 0; i < chargeDistance; i++) {
      final nextPosition = _getNewPosition(direction, targetPosition);
      if (tileMap.isWalkable(nextPosition) &&
          (collisionDetector?.canMoveTo(this, nextPosition) ?? true)) {
        targetPosition = nextPosition;
      } else {
        break; // Stop if blocked
      }
    }

    if (targetPosition != position) {
      final fromPosition = position;
      position = targetPosition!;
      setActive();

      if (onAnimateMovement != null) {
        onAnimateMovement(id, fromPosition, targetPosition);
      }
    }
  }

  /// Area attack ability - damages all adjacent enemies (conceptual)
  Future<void> _useAreaAttackAbility(GhostCharacter player) async {
    // Show area attack message
    _dialogueManager?.showBossAttack(t.combat.bossAbilities.areaAttack);

    // This would damage all characters within range
    // For now, just mark that the ability was used
    debugPrint('BossCharacter: Boss $id performs devastating area attack!');
  }

  /// Regeneration ability - heals significant amount
  Future<void> _useRegenerationAbility() async {
    final healAmount = (maxHealth * 0.15).round(); // Heal 15% of max health
    heal(healAmount);

    // Show regeneration message with heal amount
    final regenerationMessage = t.combat.bossAbilities.regeneration
        .replaceAll('{healAmount}', healAmount.toString());
    _dialogueManager?.showBossAttack(regenerationMessage);

    debugPrint('BossCharacter: Boss $id regenerates $healAmount health');
  }

  /// Summon minions ability - spawns additional enemies
  Future<void> _useSummonMinionsAbility(TileMap tileMap) async {
    // Show summon minions message
    _dialogueManager?.showBossAttack(t.combat.bossAbilities.summonMinions);

    // This would spawn additional enemies around the boss
    // For now, just mark that the ability was used
    debugPrint('BossCharacter: Boss $id summons minions to aid in battle!');
  }

  /// Gets the cooldown for a specific ability
  int _getAbilityCooldown(BossAbility ability) {
    switch (ability) {
      case BossAbility.charge:
        return 3;
      case BossAbility.areaAttack:
        return 5;
      case BossAbility.regeneration:
        return 7;
      case BossAbility.summonMinions:
        return 10;
    }
  }

  /// Executes aggressive phase AI (direct assault)
  Future<void> _executeAggressivePhase(
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    // Always move toward player aggressively
    await _moveTowardsPlayer(
      player,
      tileMap,
      collisionDetector: collisionDetector,
      onAnimateMovement: onAnimateMovement,
    );
  }

  /// Executes tactical phase AI (mix of advance and positioning)
  Future<void> _executeTacticalPhase(
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final distance = position.distanceTo(player.position);

    if (distance > 4) {
      // Move closer if far away
      await _moveTowardsPlayer(
        player,
        tileMap,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      );
    } else if (distance < 2) {
      // Move away if too close (tactical positioning)
      await _moveAwayFromPlayer(
        player,
        tileMap,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      );
    } else {
      // Circle around player
      await _circleAroundPlayer(
        player,
        tileMap,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      );
    }
  }

  /// Executes desperate phase AI (erratic and aggressive)
  Future<void> _executeDesperatePhase(
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    // Desperate phase: erratic movement with high aggression
    final behavior = _random.nextInt(3);

    switch (behavior) {
      case 0:
        // Direct charge
        await _moveTowardsPlayer(
          player,
          tileMap,
          collisionDetector: collisionDetector,
          onAnimateMovement: onAnimateMovement,
        );
        break;
      case 1:
        // Random movement
        await _wanderRandomly(
          tileMap,
          player: player,
          collisionDetector: collisionDetector,
          onAnimateMovement: onAnimateMovement,
        );
        break;
      case 2:
        // Circle player aggressively
        await _circleAroundPlayer(
          player,
          tileMap,
          collisionDetector: collisionDetector,
          onAnimateMovement: onAnimateMovement,
        );
        break;
    }
  }

  /// Moves away from the player (tactical retreat)
  Future<void> _moveAwayFromPlayer(
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final direction = _getDirectionAwayFrom(player.position);
    if (direction != null) {
      await _attemptMove(
        direction,
        tileMap,
        player: player,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      );
    }
  }

  /// Circles around the player for tactical positioning
  Future<void> _circleAroundPlayer(
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    // Get perpendicular directions to player
    final toPlayer = _getDirectionTowards(player.position);
    if (toPlayer == null) return;

    final perpendicularDirections = _getPerpendicularDirections(toPlayer);
    perpendicularDirections.shuffle(_random);

    for (final direction in perpendicularDirections) {
      if (await _attemptMove(
        direction,
        tileMap,
        player: player,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      )) {
        return;
      }
    }
  }

  /// Gets direction away from a target position
  Direction? _getDirectionAwayFrom(Position target) {
    final dx = position.x - target.x;
    final dz = position.z - target.z;

    if (dx.abs() > dz.abs()) {
      return dx > 0 ? Direction.east : Direction.west;
    } else if (dz.abs() > dx.abs()) {
      return dz > 0 ? Direction.south : Direction.north;
    } else if (dx != 0) {
      return dx > 0 ? Direction.east : Direction.west;
    } else if (dz != 0) {
      return dz > 0 ? Direction.south : Direction.north;
    }

    return null;
  }

  /// Gets perpendicular directions to a given direction
  List<Direction> _getPerpendicularDirections(Direction direction) {
    switch (direction) {
      case Direction.north:
      case Direction.south:
        return [Direction.east, Direction.west];
      case Direction.east:
      case Direction.west:
        return [Direction.north, Direction.south];
    }
  }

  /// Gets new position in a specific direction from a starting position
  Position _getNewPosition(Direction direction, [Position? from]) {
    final startPos = from ?? position;
    switch (direction) {
      case Direction.north:
        return startPos.add(0, -1);
      case Direction.south:
        return startPos.add(0, 1);
      case Direction.west:
        return startPos.add(-1, 0);
      case Direction.east:
        return startPos.add(1, 0);
    }
  }

  /// Enhanced attack that deals more damage than regular enemies
  @override
  int attackPlayer(GhostCharacter player) {
    // Boss deals significantly more damage
    final baseDamage = (baseCombatStrength! * 0.8).round();
    final randomBonus = (baseCombatStrength! * 0.4 * _random.nextDouble())
        .round();
    final phaseDamageMultiplier = currentPhase == BossPhase.desperate
        ? 1.5
        : 1.0;

    final totalDamage = ((baseDamage + randomBonus) * phaseDamageMultiplier)
        .round();

    debugPrint(
      'BossCharacter: Boss $id (${currentPhase.name} phase) attacks player for $totalDamage damage',
    );

    return totalDamage;
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

  /// Moves the boss towards the player's position
  Future<void> _moveTowardsPlayer(
    GhostCharacter player,
    TileMap tileMap, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final targetPosition = lastKnownPlayerPosition ?? player.position;
    final direction = _getDirectionTowards(targetPosition);

    if (direction != null) {
      if (!await _attemptMove(
        direction,
        tileMap,
        player: player,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      )) {
        // If direct path is blocked, try alternative directions
        await _tryAlternativeDirections(
          targetPosition,
          tileMap,
          player,
          collisionDetector: collisionDetector,
          onAnimateMovement: onAnimateMovement,
        );
      }
    } else {
      // Already at target position, stay idle
      setIdle();
    }
  }

  /// Tries alternative directions when direct path to player is blocked
  Future<void> _tryAlternativeDirections(
    Position target,
    TileMap tileMap,
    GhostCharacter player, {
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final dx = target.x - position.x;
    final dz = target.z - position.z;

    // Try perpendicular directions first
    List<Direction> alternativeDirections = [];

    if (dx.abs() > dz.abs()) {
      // Moving primarily horizontal, try vertical alternatives
      alternativeDirections = [Direction.north, Direction.south];
    } else {
      // Moving primarily vertical, try horizontal alternatives
      alternativeDirections = [Direction.east, Direction.west];
    }

    // Shuffle to avoid predictable patterns
    alternativeDirections.shuffle(_random);

    for (final direction in alternativeDirections) {
      if (await _attemptMove(
        direction,
        tileMap,
        player: player,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      )) {
        debugPrint('BossCharacter: $id found alternative path toward player');
        return;
      }
    }

    // If no alternative works, stay idle this turn
    setIdle();
    debugPrint('BossCharacter: $id blocked, staying in place');
  }

  /// Makes the boss wander randomly
  Future<void> _wanderRandomly(
    TileMap tileMap, {
    GhostCharacter? player,
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final directions = Direction.values;
    final shuffledDirections = List<Direction>.from(directions)
      ..shuffle(_random);

    for (final direction in shuffledDirections) {
      if (await _attemptMove(
        direction,
        tileMap,
        player: player,
        collisionDetector: collisionDetector,
        onAnimateMovement: onAnimateMovement,
      )) {
        break; // Successfully moved
      }
    }
  }

  /// Attempts to move in the specified direction
  Future<bool> _attemptMove(
    Direction direction,
    TileMap tileMap, {
    GhostCharacter? player,
    CollisionDetector? collisionDetector,
    Function(String, Position, Position)? onAnimateMovement,
  }) async {
    final newPosition = _getNewPosition(direction);

    // Use CollisionDetector if available, otherwise fall back to manual checks
    if (collisionDetector != null) {
      if (!collisionDetector.canMoveTo(this, newPosition)) {
        return false;
      }
    } else {
      // Legacy collision detection (keep for backward compatibility)

      // Check if the new position would overlap with player
      if (player != null && newPosition == player.position) {
        debugPrint(
          'BossCharacter: $id cannot move to $newPosition - player is there',
        );
        return false;
      }

      // Check if the new position is valid and walkable
      if (!tileMap.isWalkable(newPosition)) {
        return false;
      }
    }

    // Store previous position for animation
    final fromPosition = position;

    // Perform the movement (update game logic position immediately)
    final success = moveTo(newPosition, collisionDetector);
    if (success) {
      _facingDirection =
          direction; // Update facing direction when moving successfully
      setActive(); // Boss is moving, not idle

      // Trigger animation if callback provided
      if (onAnimateMovement != null) {
        onAnimateMovement(id, fromPosition, newPosition);
      }

      debugPrint('BossCharacter: $id moved to $newPosition');
    }

    return success;
  }

  /// Checks if the boss encounter should trigger victory conditions
  bool shouldTriggerVictory() {
    return isDefeated && currentPhase == BossPhase.defeated;
  }

  /// Gets the current facing direction for animation purposes
  @override
  Direction get facingDirection => _facingDirection;

  /// Gets default abilities for a boss
  static List<BossAbility> _getDefaultAbilities() {
    return [
      BossAbility.charge,
      BossAbility.areaAttack,
      BossAbility.regeneration,
    ];
  }

  /// Gets default attack patterns for a boss
  static List<AttackPattern> _getDefaultAttackPatterns() {
    return [AttackPattern.directAssault, AttackPattern.circling];
  }

  @override
  String toString() {
    return 'BossCharacter($id) at $position [Phase: ${currentPhase.name}, '
        'Health: $health/$maxHealth, Encountered: $hasBeenEncountered, '
        'Defeated: $isDefeated]';
  }
}

/// Different phases of boss behavior
enum BossPhase {
  aggressive, // High health: direct assault
  tactical, // Medium health: strategic positioning
  desperate, // Low health: erratic and dangerous
  defeated; // Zero health: boss is defeated

  String get displayName {
    switch (this) {
      case BossPhase.aggressive:
        return 'Aggressive';
      case BossPhase.tactical:
        return 'Tactical';
      case BossPhase.desperate:
        return 'Desperate';
      case BossPhase.defeated:
        return 'Defeated';
    }
  }
}

/// Special abilities that bosses can use
enum BossAbility {
  charge, // Move multiple tiles toward player
  areaAttack, // Damage all adjacent characters
  regeneration, // Heal significant health
  summonMinions; // Spawn additional enemies

  String get displayName {
    switch (this) {
      case BossAbility.charge:
        return 'Charge';
      case BossAbility.areaAttack:
        return 'Area Attack';
      case BossAbility.regeneration:
        return 'Regeneration';
      case BossAbility.summonMinions:
        return 'Summon Minions';
    }
  }
}

/// Attack patterns for boss behavior
enum AttackPattern {
  directAssault, // Move directly toward player
  circling; // Circle around player

  String get displayName {
    switch (this) {
      case AttackPattern.directAssault:
        return 'Direct Assault';
      case AttackPattern.circling:
        return 'Circling';
    }
  }
}
