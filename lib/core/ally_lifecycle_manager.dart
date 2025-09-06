import 'ally_character.dart';
import 'health_system.dart';

/// Manages the lifecycle of ally characters including satisfaction-based removal
class AllyLifecycleManager {
  /// List of allies being managed
  final List<AllyCharacter> _allies = [];
  
  /// Health system for tracking ally health
  final HealthSystem healthSystem;
  
  /// List of allies that became satisfied and should be removed
  final List<AllyCharacter> _satisfiedAllies = [];
  
  /// Callbacks for lifecycle events
  final List<Function(AllyCharacter)> _onAllyAdded = [];
  final List<Function(AllyCharacter)> _onAllyRemoved = [];
  final List<Function(AllyCharacter)> _onAllySatisfied = [];

  AllyLifecycleManager({HealthSystem? healthSystem})
      : healthSystem = healthSystem ?? HealthSystem();

  /// Adds an ally to be managed
  void addAlly(AllyCharacter ally) {
    if (!_allies.contains(ally)) {
      _allies.add(ally);
      
      // Notify listeners
      for (final callback in _onAllyAdded) {
        callback(ally);
      }
    }
  }

  /// Removes an ally from management
  void removeAlly(AllyCharacter ally) {
    if (_allies.remove(ally)) {
      // Clean up health tracking
      healthSystem.removeCharacter(ally.id);
      
      // Notify listeners
      for (final callback in _onAllyRemoved) {
        callback(ally);
      }
    }
  }

  /// Updates all allies and handles satisfaction-based removal
  void updateAllies() {
    final alliesToRemove = <AllyCharacter>[];
    
    for (final ally in _allies) {
      // Update ally satisfaction
      _updateAllySatisfaction(ally);
      
      // Check if ally should be removed due to satisfaction
      if (ally.isSatisfied) {
        alliesToRemove.add(ally);
        _satisfiedAllies.add(ally);
        
        // Notify listeners
        for (final callback in _onAllySatisfied) {
          callback(ally);
        }
      }
    }
    
    // Remove satisfied allies
    for (final ally in alliesToRemove) {
      removeAlly(ally);
    }
  }

  /// Updates an ally's satisfaction based on various factors
  void _updateAllySatisfaction(AllyCharacter ally) {
    // Satisfaction decreases over time (handled in AllyCharacter.updateAI)
    
    // Additional satisfaction loss based on health
    if (ally.healthPercentage < 0.3) {
      // Low health causes faster satisfaction loss
      if (DateTime.now().millisecondsSinceEpoch % 100 == 0) { // Occasional check
        ally.satisfaction = (ally.satisfaction - 1).clamp(0, ally.maxSatisfaction);
      }
    }
    
    // Satisfaction loss when taking damage is handled in AllyCharacter.takeDamage
  }

  /// Increases satisfaction for all allies (e.g., when player does something good)
  void increaseSatisfactionForAll(int amount) {
    for (final ally in _allies) {
      ally.increaseSatisfaction(amount);
    }
  }

  /// Increases satisfaction for a specific ally
  void increaseSatisfactionFor(AllyCharacter ally, int amount) {
    if (_allies.contains(ally)) {
      ally.increaseSatisfaction(amount);
    }
  }

  /// Gets all active allies
  List<AllyCharacter> get activeAllies => List.unmodifiable(_allies);

  /// Gets all satisfied allies that were removed
  List<AllyCharacter> get satisfiedAllies => List.unmodifiable(_satisfiedAllies);

  /// Gets the number of active allies
  int get allyCount => _allies.length;

  /// Gets allies with low satisfaction (below 30%)
  List<AllyCharacter> get alliesWithLowSatisfaction {
    return _allies.where((ally) => ally.satisfactionPercentage < 0.3).toList();
  }

  /// Gets allies with critical health (below 20%)
  List<AllyCharacter> get alliesWithCriticalHealth {
    return _allies.where((ally) => ally.healthPercentage < 0.2).toList();
  }

  /// Gets allies currently in combat
  List<AllyCharacter> get alliesInCombat {
    return _allies.where((ally) => ally.isInCombat).toList();
  }

  /// Registers a callback for when an ally is added
  void onAllyAdded(Function(AllyCharacter) callback) {
    _onAllyAdded.add(callback);
  }

  /// Registers a callback for when an ally is removed
  void onAllyRemoved(Function(AllyCharacter) callback) {
    _onAllyRemoved.add(callback);
  }

  /// Registers a callback for when an ally becomes satisfied
  void onAllySatisfied(Function(AllyCharacter) callback) {
    _onAllySatisfied.add(callback);
  }

  /// Removes all callbacks
  void clearCallbacks() {
    _onAllyAdded.clear();
    _onAllyRemoved.clear();
    _onAllySatisfied.clear();
  }

  /// Gets statistics about ally management
  AllyLifecycleStats get stats {
    return AllyLifecycleStats(
      activeAllies: _allies.length,
      satisfiedAllies: _satisfiedAllies.length,
      alliesInCombat: alliesInCombat.length,
      alliesWithLowSatisfaction: alliesWithLowSatisfaction.length,
      alliesWithCriticalHealth: alliesWithCriticalHealth.length,
      averageSatisfaction: _allies.isEmpty ? 0.0 : 
          _allies.map((a) => a.satisfactionPercentage).reduce((a, b) => a + b) / _allies.length,
      averageHealth: _allies.isEmpty ? 0.0 :
          _allies.map((a) => a.healthPercentage).reduce((a, b) => a + b) / _allies.length,
    );
  }

  /// Clears all allies and satisfied allies
  void clear() {
    final alliesClone = List<AllyCharacter>.from(_allies);
    for (final ally in alliesClone) {
      removeAlly(ally);
    }
    _satisfiedAllies.clear();
  }

  /// Forces an ally to become satisfied (for testing or special events)
  void forceSatisfaction(AllyCharacter ally) {
    if (_allies.contains(ally)) {
      ally.satisfaction = 0;
      ally.state = AllyState.satisfied;
    }
  }

  /// Restores an ally's satisfaction to full (for special events)
  void restoreSatisfaction(AllyCharacter ally) {
    if (_allies.contains(ally)) {
      ally.satisfaction = ally.maxSatisfaction;
      if (ally.state == AllyState.satisfied) {
        ally.state = AllyState.following;
      }
    }
  }

  /// Gets detailed information about an ally
  AllyInfo? getAllyInfo(AllyCharacter ally) {
    if (!_allies.contains(ally)) return null;
    
    return AllyInfo(
      ally: ally,
      healthStats: healthSystem.getHealthStats(ally.id),
      timeAsAlly: DateTime.now().difference(DateTime.now()), // Would need to track creation time
      combatParticipation: 0, // Would need to track combat events
    );
  }
}

/// Statistics about ally lifecycle management
class AllyLifecycleStats {
  final int activeAllies;
  final int satisfiedAllies;
  final int alliesInCombat;
  final int alliesWithLowSatisfaction;
  final int alliesWithCriticalHealth;
  final double averageSatisfaction;
  final double averageHealth;

  AllyLifecycleStats({
    required this.activeAllies,
    required this.satisfiedAllies,
    required this.alliesInCombat,
    required this.alliesWithLowSatisfaction,
    required this.alliesWithCriticalHealth,
    required this.averageSatisfaction,
    required this.averageHealth,
  });

  /// Gets the total number of allies ever managed
  int get totalAlliesEver => activeAllies + satisfiedAllies;

  /// Gets the satisfaction retention rate (0.0 to 1.0)
  double get satisfactionRetentionRate {
    if (totalAlliesEver == 0) return 1.0;
    return activeAllies / totalAlliesEver;
  }

  @override
  String toString() {
    return 'AllyLifecycleStats(Active: $activeAllies, Satisfied: $satisfiedAllies, '
           'Combat: $alliesInCombat, Avg Satisfaction: ${(averageSatisfaction * 100).toStringAsFixed(1)}%, '
           'Avg Health: ${(averageHealth * 100).toStringAsFixed(1)}%)';
  }
}

/// Detailed information about a specific ally
class AllyInfo {
  final AllyCharacter ally;
  final HealthStats? healthStats;
  final Duration timeAsAlly;
  final int combatParticipation;

  AllyInfo({
    required this.ally,
    required this.healthStats,
    required this.timeAsAlly,
    required this.combatParticipation,
  });

  /// Gets a summary of the ally's status
  String get statusSummary {
    final health = '${(ally.healthPercentage * 100).toStringAsFixed(0)}%';
    final satisfaction = '${(ally.satisfactionPercentage * 100).toStringAsFixed(0)}%';
    return '${ally.id}: Health $health, Satisfaction $satisfaction, State: ${ally.state.displayName}';
  }

  @override
  String toString() => statusSummary;
}