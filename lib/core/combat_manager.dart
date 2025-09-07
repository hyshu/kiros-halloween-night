import 'dart:math';
import 'ally_character.dart';
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
    // Enemy becomes satisfied and will be removed
    enemy.setSatisfied();
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
