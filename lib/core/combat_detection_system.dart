import 'ally_character.dart';
import 'enemy_character.dart';
import 'position.dart';

/// System for detecting and managing combat encounters between allies and enemies
class CombatDetectionSystem {
  /// Combat detection range
  static const int combatRange = 1;
  
  /// Extended detection range for potential combat
  static const int detectionRange = 4;
  
  /// List of currently detected combat encounters
  final List<CombatEncounter> _detectedEncounters = [];
  
  /// List of potential combat encounters (enemies within detection range)
  final List<PotentialCombatEncounter> _potentialEncounters = [];

  /// Detects all combat encounters between allies and hostile enemies
  List<CombatEncounter> detectCombatEncounters(
    List<AllyCharacter> allies,
    List<EnemyCharacter> hostileEnemies,
  ) {
    _detectedEncounters.clear();
    _potentialEncounters.clear();
    
    for (final ally in allies) {
      if (!ally.isAlive || ally.isSatisfied) continue;
      
      for (final enemy in hostileEnemies) {
        if (!enemy.isAlive || !enemy.isHostile || !enemy.isProximityActive) continue;
        
        final distance = ally.position.distanceTo(enemy.position);
        
        if (distance <= combatRange) {
          // Direct combat encounter
          final encounter = CombatEncounter(
            ally: ally,
            enemy: enemy,
            distance: distance,
            encounterType: CombatEncounterType.direct,
            detectedAt: DateTime.now(),
          );
          _detectedEncounters.add(encounter);
        } else if (distance <= detectionRange) {
          // Potential combat encounter
          final potentialEncounter = PotentialCombatEncounter(
            ally: ally,
            enemy: enemy,
            distance: distance,
            detectedAt: DateTime.now(),
          );
          _potentialEncounters.add(potentialEncounter);
        }
      }
    }
    
    return List.unmodifiable(_detectedEncounters);
  }

  /// Gets potential combat encounters (enemies within detection range)
  List<PotentialCombatEncounter> getPotentialEncounters() {
    return List.unmodifiable(_potentialEncounters);
  }

  /// Checks if a specific ally is in combat
  bool isAllyInCombat(AllyCharacter ally) {
    return _detectedEncounters.any((encounter) => encounter.ally == ally);
  }

  /// Checks if a specific enemy is in combat
  bool isEnemyInCombat(EnemyCharacter enemy) {
    return _detectedEncounters.any((encounter) => encounter.enemy == enemy);
  }

  /// Gets all enemies currently in combat with allies
  List<EnemyCharacter> getEnemiesInCombat() {
    return _detectedEncounters.map((encounter) => encounter.enemy).toList();
  }

  /// Gets all allies currently in combat
  List<AllyCharacter> getAlliesInCombat() {
    return _detectedEncounters.map((encounter) => encounter.ally).toList();
  }

  /// Finds the closest enemy to a specific ally
  EnemyCharacter? findClosestEnemyToAlly(
    AllyCharacter ally,
    List<EnemyCharacter> hostileEnemies,
  ) {
    EnemyCharacter? closestEnemy;
    double closestDistance = double.infinity;
    
    for (final enemy in hostileEnemies) {
      if (!enemy.isAlive || !enemy.isHostile || !enemy.isProximityActive) continue;
      
      final distance = ally.position.distanceTo(enemy.position).toDouble();
      if (distance < closestDistance) {
        closestDistance = distance;
        closestEnemy = enemy;
      }
    }
    
    return closestEnemy;
  }

  /// Finds all enemies within a specific range of an ally
  List<EnemyCharacter> findEnemiesInRange(
    AllyCharacter ally,
    List<EnemyCharacter> hostileEnemies,
    int range,
  ) {
    return hostileEnemies.where((enemy) {
      return enemy.isAlive &&
             enemy.isHostile &&
             enemy.isProximityActive &&
             ally.position.distanceTo(enemy.position) <= range;
    }).toList();
  }

  /// Predicts if an ally will engage in combat based on current positions and movement
  bool predictCombatEngagement(
    AllyCharacter ally,
    EnemyCharacter enemy,
    int turnsAhead,
  ) {
    // Simple prediction based on current distance and movement patterns
    final currentDistance = ally.position.distanceTo(enemy.position);
    
    if (currentDistance <= combatRange) {
      return true; // Already in combat range
    }
    
    if (currentDistance > detectionRange) {
      return false; // Too far to engage
    }
    
    // Estimate if they'll be in combat range within the specified turns
    // This is a simplified prediction - in a full implementation, you'd consider
    // movement patterns, obstacles, and AI behavior
    final estimatedApproachRate = 1.0; // Assume 1 tile per turn approach
    final turnsToContact = (currentDistance - combatRange) / estimatedApproachRate;
    
    return turnsToContact <= turnsAhead;
  }

  /// Gets combat statistics for monitoring and debugging
  CombatDetectionStats getStats() {
    final directCombats = _detectedEncounters.where(
      (e) => e.encounterType == CombatEncounterType.direct
    ).length;
    
    final potentialCombats = _potentialEncounters.length;
    
    final uniqueAlliesInCombat = _detectedEncounters
        .map((e) => e.ally.id)
        .toSet()
        .length;
    
    final uniqueEnemiesInCombat = _detectedEncounters
        .map((e) => e.enemy.id)
        .toSet()
        .length;
    
    return CombatDetectionStats(
      directCombatEncounters: directCombats,
      potentialCombatEncounters: potentialCombats,
      uniqueAlliesInCombat: uniqueAlliesInCombat,
      uniqueEnemiesInCombat: uniqueEnemiesInCombat,
      totalEncounters: _detectedEncounters.length,
    );
  }

  /// Clears all detected encounters (call at end of game tick)
  void clearDetectedEncounters() {
    _detectedEncounters.clear();
    _potentialEncounters.clear();
  }
}

/// Represents a detected combat encounter between an ally and enemy
class CombatEncounter {
  final AllyCharacter ally;
  final EnemyCharacter enemy;
  final int distance;
  final CombatEncounterType encounterType;
  final DateTime detectedAt;

  CombatEncounter({
    required this.ally,
    required this.enemy,
    required this.distance,
    required this.encounterType,
    required this.detectedAt,
  });

  /// Returns true if this encounter involves the specified characters
  bool involves(AllyCharacter ally, EnemyCharacter enemy) {
    return this.ally == ally && this.enemy == enemy;
  }

  /// Gets the duration since this encounter was detected
  Duration get duration => DateTime.now().difference(detectedAt);

  /// Returns true if this is a direct combat encounter
  bool get isDirectCombat => encounterType == CombatEncounterType.direct;

  /// Returns true if both characters are still alive
  bool get isValid => ally.isAlive && enemy.isAlive && enemy.isHostile;

  @override
  String toString() {
    return 'CombatEncounter(${ally.id} vs ${enemy.id}, '
           'distance: $distance, type: ${encounterType.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CombatEncounter &&
           other.ally == ally &&
           other.enemy == enemy;
  }

  @override
  int get hashCode => Object.hash(ally, enemy);
}

/// Represents a potential combat encounter (enemy within detection range)
class PotentialCombatEncounter {
  final AllyCharacter ally;
  final EnemyCharacter enemy;
  final int distance;
  final DateTime detectedAt;

  PotentialCombatEncounter({
    required this.ally,
    required this.enemy,
    required this.distance,
    required this.detectedAt,
  });

  /// Gets the duration since this potential encounter was detected
  Duration get duration => DateTime.now().difference(detectedAt);

  /// Returns true if both characters are still alive and enemy is hostile
  bool get isValid => ally.isAlive && enemy.isAlive && enemy.isHostile;

  /// Estimates turns until potential combat based on distance
  int get estimatedTurnsToCombat => (distance - CombatDetectionSystem.combatRange).clamp(0, 10);

  @override
  String toString() {
    return 'PotentialCombatEncounter(${ally.id} vs ${enemy.id}, '
           'distance: $distance, ETA: ${estimatedTurnsToCombat} turns)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PotentialCombatEncounter &&
           other.ally == ally &&
           other.enemy == enemy;
  }

  @override
  int get hashCode => Object.hash(ally, enemy);
}

/// Types of combat encounters
enum CombatEncounterType {
  direct,     // Characters are adjacent (within combat range)
  potential;  // Characters are within detection range

  String get displayName {
    switch (this) {
      case CombatEncounterType.direct:
        return 'Direct Combat';
      case CombatEncounterType.potential:
        return 'Potential Combat';
    }
  }
}

/// Statistics about combat detection
class CombatDetectionStats {
  final int directCombatEncounters;
  final int potentialCombatEncounters;
  final int uniqueAlliesInCombat;
  final int uniqueEnemiesInCombat;
  final int totalEncounters;

  CombatDetectionStats({
    required this.directCombatEncounters,
    required this.potentialCombatEncounters,
    required this.uniqueAlliesInCombat,
    required this.uniqueEnemiesInCombat,
    required this.totalEncounters,
  });

  /// Gets the ratio of direct to potential combat encounters
  double get directToPotentialRatio {
    if (potentialCombatEncounters == 0) return double.infinity;
    return directCombatEncounters / potentialCombatEncounters;
  }

  /// Returns true if there are any active combat encounters
  bool get hasActiveCombat => directCombatEncounters > 0;

  /// Returns true if there are any potential combat encounters
  bool get hasPotentialCombat => potentialCombatEncounters > 0;

  @override
  String toString() {
    return 'CombatDetectionStats(Direct: $directCombatEncounters, '
           'Potential: $potentialCombatEncounters, '
           'Allies: $uniqueAlliesInCombat, Enemies: $uniqueEnemiesInCombat)';
  }
}