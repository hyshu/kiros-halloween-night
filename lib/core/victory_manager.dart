import 'package:flutter/foundation.dart';

import 'boss_character.dart';
import 'boss_manager.dart';
import 'dialogue_manager.dart';
import 'ghost_character.dart';

/// Manages victory conditions and game completion
class VictoryManager extends ChangeNotifier {
  /// Whether the game has been won
  bool _gameWon = false;

  /// Whether victory has been triggered
  bool _victoryTriggered = false;

  /// Reference to the dialogue manager for victory messages
  DialogueManager? _dialogueManager;

  /// Reference to the boss manager
  BossManager? _bossManager;

  /// Victory callbacks
  Function()? _onVictory;
  Function()? _onGameComplete;

  /// Victory statistics
  final Map<String, dynamic> _victoryStats = {};

  /// Getters
  bool get gameWon => _gameWon;
  bool get victoryTriggered => _victoryTriggered;
  Map<String, dynamic> get victoryStats => Map.unmodifiable(_victoryStats);

  /// Initializes the victory manager
  void initialize({
    DialogueManager? dialogueManager,
    BossManager? bossManager,
    Function()? onVictory,
    Function()? onGameComplete,
  }) {
    _dialogueManager = dialogueManager;
    _bossManager = bossManager;
    _onVictory = onVictory;
    _onGameComplete = onGameComplete;

    debugPrint('VictoryManager: Initialized');
  }

  /// Checks victory conditions each turn
  void checkVictoryConditions(GhostCharacter player) {
    if (_gameWon || _victoryTriggered) return;

    // Primary victory condition: Boss is defeated
    if (_checkBossVictory()) {
      _triggerVictory(VictoryType.bossDefeated, player);
      return;
    }

    // Secondary victory conditions (if needed)
    if (_checkAlternateVictoryConditions(player)) {
      _triggerVictory(VictoryType.alternate, player);
      return;
    }
  }

  /// Checks if the boss has been defeated
  bool _checkBossVictory() {
    if (_bossManager == null) return false;

    final boss = _bossManager!.currentBoss;
    return boss != null &&
        boss.isDefeated &&
        boss.currentPhase == BossPhase.defeated;
  }

  /// Checks alternate victory conditions (for future expansion)
  bool _checkAlternateVictoryConditions(GhostCharacter player) {
    // Future: Could add alternate victory conditions like:
    // - Collect all special items
    // - Reach a certain level
    // - Complete specific objectives
    return false;
  }

  /// Triggers victory with comprehensive handling
  void _triggerVictory(VictoryType victoryType, GhostCharacter player) {
    if (_victoryTriggered) return;

    _victoryTriggered = true;
    debugPrint('VictoryManager: Victory triggered! Type: ${victoryType.name}');

    // Record victory statistics
    _recordVictoryStats(victoryType, player);

    // Show victory sequence
    _showVictorySequence(victoryType);

    // Trigger callbacks
    if (_onVictory != null) {
      _onVictory!();
    }

    // Mark game as won
    _gameWon = true;

    // Trigger game complete after victory sequence
    Future.delayed(const Duration(seconds: 5), () {
      if (_onGameComplete != null) {
        _onGameComplete!();
      }
    });

    notifyListeners();
  }

  /// Records victory statistics
  void _recordVictoryStats(VictoryType victoryType, GhostCharacter player) {
    _victoryStats.clear();
    _victoryStats.addAll({
      'victoryType': victoryType.name,
      'playerHealth': player.health,
      'playerMaxHealth': player.maxHealth,
      'playerPosition': player.position.toString(),
      'victoryTimestamp': DateTime.now().toIso8601String(),
      'bossStats': _bossManager?.getBossStats() ?? {},
    });

    debugPrint('VictoryManager: Victory stats recorded: $_victoryStats');
  }

  /// Shows the victory sequence with dramatic dialogue
  void _showVictorySequence(VictoryType victoryType) {
    if (_dialogueManager == null) return;

    switch (victoryType) {
      case VictoryType.bossDefeated:
        _showBossVictorySequence();
        break;
      case VictoryType.alternate:
        _showAlternateVictorySequence();
        break;
    }
  }

  /// Shows the boss victory sequence
  void _showBossVictorySequence() {
    if (_dialogueManager == null) return;

    final victoryMessages = [
      "🎉 VICTORY! 🎉",
      "",
      "The ancient Vampire Lord crumbles to dust before your might!",
      "Your ghostly powers and loyal allies have triumphed!",
      "",
      "The Halloween realm is saved from eternal darkness!",
      "You have proven yourself the true Spook Master!",
      "",
      "Final Statistics:",
      "Boss Defeated: ✓",
      "Realm Saved: ✓",
      "Halloween Quest: COMPLETE!",
      "",
      "🏆 CONGRATULATIONS! 🏆",
      "You have completed the Kiro Halloween Adventure!",
    ];

    // Show victory messages with dramatic pauses
    for (int i = 0; i < victoryMessages.length; i++) {
      Future.delayed(Duration(milliseconds: 800 * i), () {
        if (victoryMessages[i].isNotEmpty) {
          _dialogueManager!.showVictory(victoryMessages[i]);
        }
      });
    }
  }

  /// Shows alternate victory sequence (for future expansion)
  void _showAlternateVictorySequence() {
    if (_dialogueManager == null) return;

    _dialogueManager!.showVictory("Victory achieved through alternate means!");
  }

  /// Forces victory for testing purposes
  void forceVictory(
    GhostCharacter player, {
    VictoryType type = VictoryType.bossDefeated,
  }) {
    debugPrint('VictoryManager: Forcing victory for testing');
    _triggerVictory(type, player);
  }

  /// Checks if victory conditions are met (without triggering)
  bool wouldTriggerVictory() {
    if (_gameWon || _victoryTriggered) return false;
    return _checkBossVictory();
  }

  /// Gets victory progress information
  Map<String, dynamic> getVictoryProgress() {
    return {
      'gameWon': _gameWon,
      'victoryTriggered': _victoryTriggered,
      'bossDefeated': _checkBossVictory(),
      'bossExists': _bossManager?.hasBoss ?? false,
      'bossEncountered': _bossManager?.encounterInitiated ?? false,
      'victoryConditionsMet': wouldTriggerVictory(),
    };
  }

  /// Resets victory manager to initial state
  void reset() {
    _gameWon = false;
    _victoryTriggered = false;
    _victoryStats.clear();
    debugPrint('VictoryManager: Reset to initial state');
    notifyListeners();
  }

  @override
  String toString() {
    return 'VictoryManager(Won: $_gameWon, Triggered: $_victoryTriggered)';
  }
}

/// Types of victory conditions
enum VictoryType {
  bossDefeated, // Primary: Boss is defeated
  alternate; // Future: Alternate victory conditions

  String get displayName {
    switch (this) {
      case VictoryType.bossDefeated:
        return 'Boss Defeated';
      case VictoryType.alternate:
        return 'Alternate Victory';
    }
  }
}
