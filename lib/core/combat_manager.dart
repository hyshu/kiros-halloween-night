import 'dart:math';
import 'ally_character.dart';
import 'boss_character.dart';
import 'enemy_character.dart';
import 'enemy_spawner.dart';
import 'health_system.dart';
import 'position.dart';

/// Manages combat interactions between allies and hostile enemies
class CombatManager {
  /// Random number generator for combat calculations
  static final Random _random = Random();

  /// Base damage range for combat calculations
  static const int baseDamageMin = 5;
  static const int baseDamageMax = 15;

  /// Combat range - distance at which combat can occur
  static const int combatRange = 1;

  /// List of active combat encounters
  final List<CombatEncounter> _activeCombats = [];

  /// Health system for managing character health
  final HealthSystem healthSystem;

  CombatManager({HealthSystem? healthSystem})
    : healthSystem = healthSystem ?? HealthSystem();

  /// Processes combat between allies and hostile enemies
  List<CombatResult> processCombat(
    List<AllyCharacter> allies,
    List<EnemyCharacter> hostileEnemies,
  ) {
    final results = <CombatResult>[];

    // Find all possible combat encounters
    final encounters = _findCombatEncounters(allies, hostileEnemies);

    // Process each encounter
    for (final encounter in encounters) {
      final result = _resolveCombat(encounter);
      if (result != null) {
        results.add(result);
      }
    }

    // Clean up finished combats
    _activeCombats.removeWhere((combat) => combat.isFinished);

    return results;
  }

  /// Finds all valid combat encounters between allies and hostile enemies
  List<CombatEncounter> _findCombatEncounters(
    List<AllyCharacter> allies,
    List<EnemyCharacter> hostileEnemies,
  ) {
    final encounters = <CombatEncounter>[];

    for (final ally in allies) {
      if (!ally.isAlive || ally.isSatisfied) continue;

      for (final enemy in hostileEnemies) {
        if (!enemy.isAlive || !enemy.isHostile || !enemy.isProximityActive) {
          continue;
        }

        // Check if they are within combat range
        final distance = ally.position.distanceTo(enemy.position);
        if (distance <= combatRange) {
          // Check if this combat is already active
          final existingCombat = _activeCombats.firstWhere(
            (combat) => combat.involves(ally, enemy),
            orElse: () => CombatEncounter.empty(),
          );

          if (existingCombat.isEmpty) {
            // Create new combat encounter
            final encounter = CombatEncounter(
              ally: ally,
              enemy: enemy,
              startTime: DateTime.now(),
            );
            encounters.add(encounter);
            _activeCombats.add(encounter);
          } else {
            // Add existing combat to be processed
            encounters.add(existingCombat);
          }
        }
      }
    }

    return encounters;
  }

  /// Resolves a single combat encounter
  CombatResult? _resolveCombat(CombatEncounter encounter) {
    if (!encounter.ally.isAlive || !encounter.enemy.isAlive) {
      encounter.finish();
      return null;
    }

    // Calculate damage for ally attacking enemy
    final allyDamage = _calculateDamage(
      encounter.ally.effectiveCombatStrength,
      encounter.enemy.health,
    );

    // Calculate damage for enemy attacking ally
    final enemyDamage = _calculateDamage(
      _getEnemyCombatStrength(encounter.enemy),
      encounter.ally.health,
    );

    // Apply damage
    final enemyWasAlive = healthSystem.applyDamage(encounter.enemy, allyDamage);
    final allyWasAlive = healthSystem.applyDamage(encounter.ally, enemyDamage);

    // Create combat result
    final result = CombatResult(
      ally: encounter.ally,
      enemy: encounter.enemy,
      allyDamageDealt: allyDamage,
      enemyDamageDealt: enemyDamage,
      allyDefeated: !allyWasAlive,
      enemyDefeated: !enemyWasAlive,
      timestamp: DateTime.now(),
    );

    // Handle defeated characters
    if (!enemyWasAlive) {
      _handleEnemyDefeated(encounter.enemy);
      encounter.finish();
    }

    if (!allyWasAlive) {
      _handleAllyDefeated(encounter.ally);
      encounter.finish();
    }

    return result;
  }

  /// Calculates damage based on attacker strength and defender health
  int _calculateDamage(int attackerStrength, int defenderHealth) {
    // Base damage with some randomness
    final baseDamage =
        baseDamageMin + _random.nextInt(baseDamageMax - baseDamageMin + 1);

    // Apply strength modifier (higher strength = more damage)
    final strengthModifier = (attackerStrength / 10.0).clamp(0.5, 2.0);
    final modifiedDamage = (baseDamage * strengthModifier).round();

    // Add some randomness (±20%)
    final randomFactor = 0.8 + (_random.nextDouble() * 0.4);
    final finalDamage = (modifiedDamage * randomFactor).round();

    return finalDamage.clamp(
      1,
      defenderHealth,
    ); // At least 1 damage, max current health
  }

  /// Gets the combat strength of an enemy
  int _getEnemyCombatStrength(EnemyCharacter enemy) {
    // Check if this is a boss character
    if (enemy is BossCharacter) {
      return enemy.baseCombatStrength ??
          75; // Boss has much higher combat strength
    }

    // Base strength varies by enemy type
    switch (enemy.enemyType) {
      case EnemyType.human:
        return 8;
      case EnemyType.monster:
        return 12;
    }
  }

  /// Handles when an enemy is defeated in combat
  void _handleEnemyDefeated(EnemyCharacter enemy) {
    // Special handling for boss characters
    if (enemy is BossCharacter) {
      enemy.isDefeated = true;
      enemy.currentPhase = BossPhase.defeated;
      // Don't set satisfied for boss - let BossManager handle it
    } else {
      // Regular enemies become satisfied and will be removed
      enemy.setSatisfied();
    }
  }

  /// Handles when an ally is defeated in combat
  void _handleAllyDefeated(AllyCharacter ally) {
    // Ally becomes satisfied (disappears) when health reaches zero
    // This is already handled in AllyCharacter.takeDamage()
  }

  /// Gets all active combat encounters
  List<CombatEncounter> get activeCombats => List.unmodifiable(_activeCombats);

  /// Checks if a character is currently in combat
  bool isInCombat(dynamic character) {
    return _activeCombats.any(
      (combat) => combat.ally == character || combat.enemy == character,
    );
  }

  /// Forces end of all combats (for cleanup)
  void endAllCombats() {
    for (final combat in _activeCombats) {
      combat.finish();
    }
    _activeCombats.clear();
  }

  /// Special boss combat processing with enhanced mechanics
  List<CombatResult> processBossCombat(
    List<AllyCharacter> allies,
    BossCharacter boss,
  ) {
    final results = <CombatResult>[];

    if (!boss.isAlive || boss.isDefeated) return results;

    // Find allies within boss combat range (boss has extended range)
    final combatableAllies = allies.where((ally) {
      if (!ally.isAlive || ally.isSatisfied) return false;

      final distance = ally.position.distanceTo(boss.position);
      return distance <= (combatRange + 1); // Boss has extended combat range
    }).toList();

    // Process each ally vs boss encounter
    for (final ally in combatableAllies) {
      final encounter = BossCombatEncounter(
        ally: ally,
        boss: boss,
        startTime: DateTime.now(),
      );

      final result = _resolveBossCombat(encounter);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  /// Resolves boss combat with special mechanics
  CombatResult? _resolveBossCombat(BossCombatEncounter encounter) {
    if (!encounter.ally.isAlive || !encounter.boss.isAlive) {
      return null;
    }

    // Boss combat strength varies by phase
    final bossCombatStrength = _getBossCombatStrengthByPhase(encounter.boss);

    // Calculate damage for ally attacking boss
    final allyDamage = _calculateBossDamage(
      encounter.ally.effectiveCombatStrength,
      encounter.boss.health,
      false, // ally attacking boss
    );

    // Calculate damage for boss attacking ally (much higher)
    final bossDamage = _calculateBossDamage(
      bossCombatStrength,
      encounter.ally.health,
      true, // boss attacking ally
    );

    // Apply damage
    final bossWasAlive = healthSystem.applyDamage(encounter.boss, allyDamage);
    final allyWasAlive = healthSystem.applyDamage(encounter.ally, bossDamage);

    // Create boss combat result
    final result = CombatResult(
      ally: encounter.ally,
      enemy: encounter.boss, // Boss extends EnemyCharacter
      allyDamageDealt: allyDamage,
      enemyDamageDealt: bossDamage,
      allyDefeated: !allyWasAlive,
      enemyDefeated: !bossWasAlive,
      timestamp: DateTime.now(),
    );

    // Handle defeated characters
    if (!bossWasAlive) {
      _handleEnemyDefeated(encounter.boss);
    }

    if (!allyWasAlive) {
      _handleAllyDefeated(encounter.ally);
    }

    return result;
  }

  /// Gets boss combat strength based on current phase
  int _getBossCombatStrengthByPhase(BossCharacter boss) {
    final baseStrength = boss.baseCombatStrength ?? 75;

    switch (boss.currentPhase) {
      case BossPhase.aggressive:
        return baseStrength;
      case BossPhase.tactical:
        return (baseStrength * 1.2).round(); // 20% stronger
      case BossPhase.desperate:
        return (baseStrength * 1.5).round(); // 50% stronger in desperate phase
      case BossPhase.defeated:
        return 0; // No combat strength when defeated
    }
  }

  /// Calculates damage specifically for boss combat
  int _calculateBossDamage(
    int attackerStrength,
    int defenderHealth,
    bool isBossAttacking,
  ) {
    // Base damage with some randomness
    final baseDamage =
        baseDamageMin + _random.nextInt(baseDamageMax - baseDamageMin + 1);

    // Apply strength modifier
    final strengthModifier = (attackerStrength / 10.0).clamp(
      0.5,
      3.0,
    ); // Higher cap for boss
    final modifiedDamage = (baseDamage * strengthModifier).round();

    // Boss attacks are more variable and dangerous
    final randomFactor = isBossAttacking
        ? 0.7 +
              (_random.nextDouble() * 0.6) // 70-130% for boss attacks
        : 0.8 + (_random.nextDouble() * 0.4); // 80-120% for ally attacks

    final finalDamage = (modifiedDamage * randomFactor).round();

    return finalDamage.clamp(
      1,
      defenderHealth,
    ); // At least 1 damage, max current health
  }
}

/// Represents a combat encounter between an ally and an enemy
class CombatEncounter {
  final AllyCharacter ally;
  final EnemyCharacter enemy;
  final DateTime startTime;
  bool _isFinished = false;

  CombatEncounter({
    required this.ally,
    required this.enemy,
    required this.startTime,
  });

  /// Creates an empty encounter for comparison purposes
  CombatEncounter.empty()
    : ally = AllyCharacter(
        originalEnemy: EnemyCharacter(
          id: 'empty',
          position: Position(0, 0),
          modelPath: '',
        ),
      ),
      enemy = EnemyCharacter(
        id: 'empty',
        position: Position(0, 0),
        modelPath: '',
      ),
      startTime = DateTime.now(),
      _isFinished = true;

  /// Checks if this encounter involves the given characters
  bool involves(AllyCharacter ally, EnemyCharacter enemy) {
    return this.ally == ally && this.enemy == enemy;
  }

  /// Marks this encounter as finished
  void finish() {
    _isFinished = true;
  }

  /// Returns true if this encounter is finished
  bool get isFinished => _isFinished;

  /// Returns true if this is an empty encounter
  bool get isEmpty => ally.id == 'empty_ally' && enemy.id == 'empty';

  /// Gets the duration of this combat
  Duration get duration => DateTime.now().difference(startTime);

  @override
  String toString() {
    return 'CombatEncounter(${ally.id} vs ${enemy.id}, duration: ${duration.inSeconds}s)';
  }
}

/// Represents the result of a combat encounter
class CombatResult {
  final AllyCharacter ally;
  final EnemyCharacter enemy;
  final int allyDamageDealt;
  final int enemyDamageDealt;
  final bool allyDefeated;
  final bool enemyDefeated;
  final DateTime timestamp;

  CombatResult({
    required this.ally,
    required this.enemy,
    required this.allyDamageDealt,
    required this.enemyDamageDealt,
    required this.allyDefeated,
    required this.enemyDefeated,
    required this.timestamp,
  });

  /// Returns true if the combat resulted in a victory for the ally
  bool get isAllyVictory => enemyDefeated && !allyDefeated;

  /// Returns true if the combat resulted in a victory for the enemy
  bool get isEnemyVictory => allyDefeated && !enemyDefeated;

  /// Returns true if both characters were defeated
  bool get isMutualDefeat => allyDefeated && enemyDefeated;

  /// Returns true if neither character was defeated
  bool get isOngoing => !allyDefeated && !enemyDefeated;

  /// Gets a description of the combat result
  String get description {
    if (isAllyVictory) {
      return '${ally.id} defeated ${enemy.id}!';
    } else if (isEnemyVictory) {
      return '${enemy.id} defeated ${ally.id}!';
    } else if (isMutualDefeat) {
      return '${ally.id} and ${enemy.id} defeated each other!';
    } else {
      return '${ally.id} and ${enemy.id} continue fighting...';
    }
  }

  @override
  String toString() {
    return 'CombatResult($description, Ally: ${ally.health}hp, Enemy: ${enemy.health}hp)';
  }
}

/// Represents a combat encounter between an ally and a boss
class BossCombatEncounter {
  final AllyCharacter ally;
  final BossCharacter boss;
  final DateTime startTime;

  BossCombatEncounter({
    required this.ally,
    required this.boss,
    required this.startTime,
  });

  /// Gets the duration of this boss combat
  Duration get duration => DateTime.now().difference(startTime);

  @override
  String toString() {
    return 'BossCombatEncounter(${ally.id} vs BOSS ${boss.id}, duration: ${duration.inSeconds}s)';
  }
}
