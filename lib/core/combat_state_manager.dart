import 'ally_character.dart';
import 'enemy_character.dart';
import 'combat_manager.dart' as cm;
import 'combat_detection_system.dart' as cds;
import 'combat_feedback_system.dart';
import 'ally_ai.dart';

/// Manages the overall state of combat encounters and coordinates combat systems
class CombatStateManager {
  /// Combat manager for handling combat resolution
  final cm.CombatManager combatManager;

  /// Combat detection system for finding encounters
  final cds.CombatDetectionSystem detectionSystem;

  /// Combat feedback system for generating messages
  final CombatFeedbackSystem feedbackSystem;

  /// Current game tick counter
  int _currentTick = 0;

  /// Combat statistics
  final CombatStateStats _stats = CombatStateStats();

  CombatStateManager({
    cm.CombatManager? combatManager,
    cds.CombatDetectionSystem? detectionSystem,
    CombatFeedbackSystem? feedbackSystem,
  }) : combatManager = combatManager ?? cm.CombatManager(),
       detectionSystem = detectionSystem ?? cds.CombatDetectionSystem(),
       feedbackSystem = feedbackSystem ?? CombatFeedbackSystem();

  /// Processes a complete combat turn for all characters
  CombatTurnResult processCombatTurn(
    List<AllyCharacter> allies,
    List<EnemyCharacter> hostileEnemies,
  ) {
    _currentTick++;

    // 1. Update ally AI
    AllyAI.updateAlliesAI(
      allies,
      _getDummyPlayer(),
      hostileEnemies,
      _getDummyTileMap(),
    );

    // 2. Detect combat encounters
    final encounters = detectionSystem.detectCombatEncounters(
      allies,
      hostileEnemies,
    );

    // 3. Process combat for detected encounters
    final combatResults = _processCombatEncounters(encounters);

    // 4. Generate feedback messages
    final feedbackMessages = feedbackSystem.generateCombatFeedback(
      combatResults,
    );

    // 5. Handle state changes
    final stateChanges = _handleStateChanges(allies, hostileEnemies);

    // 6. Update statistics
    _updateStats(encounters, combatResults, stateChanges);

    // 7. Clean up
    detectionSystem.clearDetectedEncounters();

    return CombatTurnResult(
      tick: _currentTick,
      encounters: encounters,
      combatResults: combatResults,
      feedbackMessages: feedbackMessages,
      stateChanges: stateChanges,
      stats: _stats.copy(),
    );
  }

  /// Processes combat for detected encounters
  List<cm.CombatResult> _processCombatEncounters(
    List<cds.CombatEncounter> encounters,
  ) {
    final results = <cm.CombatResult>[];

    // Group encounters by ally-enemy pairs to avoid duplicate processing
    final processedPairs = <String>{};

    for (final encounter in encounters) {
      final pairKey = '${encounter.ally.id}-${encounter.enemy.id}';
      if (processedPairs.contains(pairKey)) continue;

      processedPairs.add(pairKey);

      // Process combat between this ally and enemy
      final combatResults = combatManager.processCombat(
        [encounter.ally],
        [encounter.enemy],
      );
      results.addAll(combatResults);
    }

    return results;
  }

  /// Handles state changes for characters
  List<StateChange> _handleStateChanges(
    List<AllyCharacter> allies,
    List<EnemyCharacter> hostileEnemies,
  ) {
    final stateChanges = <StateChange>[];

    // Check for ally state changes
    for (final ally in allies) {
      final previousState = ally.state;

      // State changes are handled by AllyAI, but we can detect them here
      if (ally.isSatisfied && previousState != AllyState.satisfied) {
        stateChanges.add(
          StateChange(
            character: ally,
            previousState: previousState.name,
            newState: AllyState.satisfied.name,
            reason: 'Ally became satisfied',
            timestamp: DateTime.now(),
          ),
        );

        // Generate feedback for satisfaction
        feedbackSystem.generateAllyStateChangeFeedback(
          ally,
          previousState,
          AllyState.satisfied,
        );
      }
    }

    // Check for enemy state changes (defeated enemies)
    for (final enemy in hostileEnemies) {
      if (!enemy.isAlive && enemy.isHostile) {
        stateChanges.add(
          StateChange(
            character: enemy,
            previousState: 'hostile',
            newState: 'defeated',
            reason: 'Enemy was defeated in combat',
            timestamp: DateTime.now(),
          ),
        );

        // Generate feedback for enemy defeat
        feedbackSystem.generateEnemyDefeatedFeedback(enemy);
      }
    }

    return stateChanges;
  }

  /// Updates combat statistics
  void _updateStats(
    List<cds.CombatEncounter> encounters,
    List<cm.CombatResult> combatResults,
    List<StateChange> stateChanges,
  ) {
    _stats.totalTicks = _currentTick;
    _stats.totalEncounters += encounters.length;
    _stats.totalCombatResults += combatResults.length;
    _stats.totalStateChanges += stateChanges.length;

    // Count victories and defeats
    for (final result in combatResults) {
      if (result.isAllyVictory) {
        _stats.allyVictories++;
      } else if (result.isEnemyVictory) {
        _stats.allyDefeats++;
      } else if (result.isMutualDefeat) {
        _stats.mutualDefeats++;
      }
    }

    // Count satisfied allies
    _stats.alliesSatisfied += stateChanges
        .where((change) => change.newState == 'satisfied')
        .length;
  }

  /// Gets the current combat state for all characters
  CombatState getCurrentCombatState(
    List<AllyCharacter> allies,
    List<EnemyCharacter> hostileEnemies,
  ) {
    final alliesInCombat = allies.where((ally) => ally.isInCombat).toList();
    final enemiesInCombat = hostileEnemies
        .where((enemy) => detectionSystem.isEnemyInCombat(enemy))
        .toList();

    final activeCombats = detectionSystem.detectCombatEncounters(
      allies,
      hostileEnemies,
    );
    final potentialEncounters = detectionSystem.getPotentialEncounters();

    return CombatState(
      tick: _currentTick,
      alliesInCombat: alliesInCombat,
      enemiesInCombat: enemiesInCombat,
      activeCombats: activeCombats,
      potentialEncounters: potentialEncounters,
      recentFeedback: feedbackSystem.recentMessages,
    );
  }

  /// Forces end of all active combats
  void endAllCombats() {
    combatManager.endAllCombats();
    detectionSystem.clearDetectedEncounters();
  }

  /// Gets combat statistics
  CombatStateStats get stats => _stats.copy();

  /// Resets all combat state
  void reset() {
    _currentTick = 0;
    combatManager.endAllCombats();
    detectionSystem.clearDetectedEncounters();
    feedbackSystem.clearMessages();
    _stats.reset();
  }

  // Dummy implementations for testing - in real game these would come from game state
  dynamic _getDummyPlayer() => null;
  dynamic _getDummyTileMap() => null;
}

/// Represents the result of processing a combat turn
class CombatTurnResult {
  final int tick;
  final List<cds.CombatEncounter> encounters;
  final List<cm.CombatResult> combatResults;
  final List<CombatFeedbackMessage> feedbackMessages;
  final List<StateChange> stateChanges;
  final CombatStateStats stats;

  CombatTurnResult({
    required this.tick,
    required this.encounters,
    required this.combatResults,
    required this.feedbackMessages,
    required this.stateChanges,
    required this.stats,
  });

  /// Returns true if any combat occurred this turn
  bool get hadCombat => combatResults.isNotEmpty;

  /// Returns true if any allies were defeated this turn
  bool get hadAllyDefeats =>
      combatResults.any((result) => result.isEnemyVictory);

  /// Returns true if any enemies were defeated this turn
  bool get hadEnemyDefeats =>
      combatResults.any((result) => result.isAllyVictory);

  /// Gets a summary of this turn's events
  String get summary {
    final parts = <String>[];

    if (encounters.isNotEmpty) {
      parts.add('${encounters.length} combat encounters');
    }

    if (combatResults.isNotEmpty) {
      parts.add('${combatResults.length} combat results');
    }

    if (stateChanges.isNotEmpty) {
      parts.add('${stateChanges.length} state changes');
    }

    if (parts.isEmpty) {
      return 'No combat activity';
    }

    return 'Turn $tick: ${parts.join(', ')}';
  }

  @override
  String toString() => summary;
}

/// Represents a character state change
class StateChange {
  final dynamic character;
  final String previousState;
  final String newState;
  final String reason;
  final DateTime timestamp;

  StateChange({
    required this.character,
    required this.previousState,
    required this.newState,
    required this.reason,
    required this.timestamp,
  });

  /// Gets the character ID
  String get characterId {
    if (character is AllyCharacter) {
      return (character as AllyCharacter).id;
    } else if (character is EnemyCharacter) {
      return (character as EnemyCharacter).id;
    }
    return 'unknown';
  }

  /// Returns true if this is an ally state change
  bool get isAllyChange => character is AllyCharacter;

  /// Returns true if this is an enemy state change
  bool get isEnemyChange => character is EnemyCharacter;

  @override
  String toString() {
    return 'StateChange($characterId: $previousState → $newState - $reason)';
  }
}

/// Represents the current combat state
class CombatState {
  final int tick;
  final List<AllyCharacter> alliesInCombat;
  final List<EnemyCharacter> enemiesInCombat;
  final List<cds.CombatEncounter> activeCombats;
  final List<cds.PotentialCombatEncounter> potentialEncounters;
  final List<CombatFeedbackMessage> recentFeedback;

  CombatState({
    required this.tick,
    required this.alliesInCombat,
    required this.enemiesInCombat,
    required this.activeCombats,
    required this.potentialEncounters,
    required this.recentFeedback,
  });

  /// Returns true if there is any active combat
  bool get hasActiveCombat => activeCombats.isNotEmpty;

  /// Returns true if there are potential combat encounters
  bool get hasPotentialCombat => potentialEncounters.isNotEmpty;

  /// Gets the total number of characters in combat
  int get totalCharactersInCombat =>
      alliesInCombat.length + enemiesInCombat.length;

  /// Gets recent combat-related feedback
  List<CombatFeedbackMessage> get recentCombatFeedback =>
      recentFeedback.where((msg) => msg.isCombatRelated).toList();

  @override
  String toString() {
    return 'CombatState(Tick: $tick, Active: ${activeCombats.length}, '
        'Potential: ${potentialEncounters.length}, '
        'Allies: ${alliesInCombat.length}, Enemies: ${enemiesInCombat.length})';
  }
}

/// Statistics about combat state management
class CombatStateStats {
  int totalTicks = 0;
  int totalEncounters = 0;
  int totalCombatResults = 0;
  int totalStateChanges = 0;
  int allyVictories = 0;
  int allyDefeats = 0;
  int mutualDefeats = 0;
  int alliesSatisfied = 0;

  /// Gets the ally victory rate
  double get allyVictoryRate {
    final totalCombats = allyVictories + allyDefeats + mutualDefeats;
    return totalCombats > 0 ? allyVictories / totalCombats : 0.0;
  }

  /// Gets the average encounters per tick
  double get averageEncountersPerTick {
    return totalTicks > 0 ? totalEncounters / totalTicks : 0.0;
  }

  /// Gets the average combat results per tick
  double get averageCombatResultsPerTick {
    return totalTicks > 0 ? totalCombatResults / totalTicks : 0.0;
  }

  /// Creates a copy of these stats
  CombatStateStats copy() {
    final copy = CombatStateStats();
    copy.totalTicks = totalTicks;
    copy.totalEncounters = totalEncounters;
    copy.totalCombatResults = totalCombatResults;
    copy.totalStateChanges = totalStateChanges;
    copy.allyVictories = allyVictories;
    copy.allyDefeats = allyDefeats;
    copy.mutualDefeats = mutualDefeats;
    copy.alliesSatisfied = alliesSatisfied;
    return copy;
  }

  /// Resets all statistics
  void reset() {
    totalTicks = 0;
    totalEncounters = 0;
    totalCombatResults = 0;
    totalStateChanges = 0;
    allyVictories = 0;
    allyDefeats = 0;
    mutualDefeats = 0;
    alliesSatisfied = 0;
  }

  @override
  String toString() {
    return 'CombatStateStats(Ticks: $totalTicks, Encounters: $totalEncounters, '
        'Results: $totalCombatResults, Victory Rate: ${(allyVictoryRate * 100).toStringAsFixed(1)}%)';
  }
}
