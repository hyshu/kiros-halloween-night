import 'package:flutter/foundation.dart';

import 'boss_character.dart';
import 'enemy_manager.dart';
import 'ghost_character.dart';
import 'position.dart';
import 'dialogue_manager.dart';
import 'candy_item.dart';

/// Manages boss encounters and victory conditions
class BossManager extends ChangeNotifier {
  /// The current boss character (null if no boss active)
  BossCharacter? _currentBoss;

  /// Whether the boss encounter has been initiated
  bool _encounterInitiated = false;

  /// Whether the boss has been defeated
  bool _bossDefeated = false;

  /// Reference to dialogue manager for boss messages
  DialogueManager? _dialogueManager;

  /// Reference to enemy manager for coordination
  EnemyManager? _enemyManager;

  /// Victory condition callbacks
  Function()? _onVictory;
  Function()? _onBossEncounterStart;
  Function()? _onBossDefeated;

  /// Encounter distance - how close player must be to trigger encounter
  static const int encounterDistance = 10;

  /// Getters
  BossCharacter? get currentBoss => _currentBoss;
  bool get encounterInitiated => _encounterInitiated;
  bool get bossDefeated => _bossDefeated;
  bool get hasBoss => _currentBoss != null;
  bool get bossIsAlive => _currentBoss?.isAlive ?? false;

  /// Initializes the boss manager
  void initialize({
    DialogueManager? dialogueManager,
    EnemyManager? enemyManager,
    Function()? onVictory,
    Function()? onBossEncounterStart,
    Function()? onBossDefeated,
  }) {
    _dialogueManager = dialogueManager;
    _enemyManager = enemyManager;
    _onVictory = onVictory;
    _onBossEncounterStart = onBossEncounterStart;
    _onBossDefeated = onBossDefeated;

    debugPrint('BossManager: Initialized');
  }

  /// Spawns the boss at the specified location
  Future<void> spawnBoss(Position bossLocation) async {
    if (_currentBoss != null) {
      debugPrint('BossManager: Boss already exists, removing previous boss');
      await removeBoss();
    }

    _currentBoss = BossCharacter.mainBoss(
      id: 'main_boss',
      position: bossLocation,
    );

    // Set dialogue manager for boss ability messages
    _currentBoss!.setDialogueManager(_dialogueManager);

    // Load the boss 3D model
    await _currentBoss!.loadModel();

    // Add boss to enemy manager for tracking
    if (_enemyManager != null) {
      await _enemyManager!.addEnemy(_currentBoss!);
    }

    debugPrint('BossManager: Boss spawned at $bossLocation');
    notifyListeners();
  }

  /// Removes the boss from the game
  Future<void> removeBoss() async {
    if (_currentBoss == null) return;

    // Remove from enemy manager
    if (_enemyManager != null) {
      _enemyManager!.removeEnemy(_currentBoss!.id);
    }

    _currentBoss = null;
    _encounterInitiated = false;
    _bossDefeated = false;

    debugPrint('BossManager: Boss removed from game');
    notifyListeners();
  }

  /// Checks if the boss encounter should be initiated based on player position
  void checkBossEncounter(Position playerPosition) {
    if (_currentBoss == null || _encounterInitiated) return;

    final distance = playerPosition.distanceTo(_currentBoss!.position);

    if (distance <= encounterDistance) {
      initiateBossEncounter();
    }
  }

  /// Initiates the boss encounter with dramatic dialogue
  void initiateBossEncounter() {
    if (_encounterInitiated || _currentBoss == null) return;

    _encounterInitiated = true;
    _currentBoss!.hasBeenEncountered = true;

    // Show dramatic boss encounter dialogue
    _showBossEncounterDialogue();

    // Trigger boss encounter callback
    if (_onBossEncounterStart != null) {
      _onBossEncounterStart!();
    }

    debugPrint('BossManager: Boss encounter initiated!');
    notifyListeners();
  }

  /// Shows the boss encounter dialogue
  void _showBossEncounterDialogue() {
    if (_dialogueManager == null) return;

    final bossDialogue = [
      "A massive, terrifying presence emerges from the shadows...",
      "The Vampire Lord has awakened! Its crimson eyes burn with ancient malice.",
      "This is the final challenge - defeat the boss to complete your Halloween quest!",
      "Use your candy wisely and command your allies to victory!",
    ];

    for (final message in bossDialogue) {
      _dialogueManager!.showBossEncounter(message);
    }
  }

  /// Processes boss turn and checks for victory conditions
  void processBossTurn(GhostCharacter player) {
    if (_currentBoss == null || !_encounterInitiated) return;

    // Check if boss was defeated this turn
    if (!_currentBoss!.isAlive && !_bossDefeated) {
      _handleBossDefeated(player);
      return;
    }

    // Handle boss phase transitions
    _handleBossPhaseChange();

    // Check for special boss events
    _checkBossSpecialEvents(player);
  }

  /// Handles when the boss is defeated
  void _handleBossDefeated(GhostCharacter player) {
    if (_bossDefeated) return;

    _bossDefeated = true;
    _currentBoss!.isDefeated = true;

    // Show victory dialogue
    _showVictoryDialogue();

    // Trigger callbacks
    if (_onBossDefeated != null) {
      _onBossDefeated!();
    }

    if (_onVictory != null) {
      _onVictory!();
    }

    debugPrint('BossManager: Boss defeated! Victory achieved!');
    notifyListeners();
  }

  /// Shows victory dialogue when boss is defeated
  void _showVictoryDialogue() {
    if (_dialogueManager == null) return;

    final victoryDialogue = [
      "The Vampire Lord lets out a final, earth-shaking roar before collapsing!",
      "Victory! You have defeated the ultimate Halloween challenge!",
      "Your ghostly powers and loyal allies have saved the realm!",
      "The Halloween quest is complete - you are the true Spook Master!",
    ];

    for (final message in victoryDialogue) {
      _dialogueManager!.showVictory(message);
    }
  }

  /// Handles boss phase changes with appropriate dialogue
  void _handleBossPhaseChange() {
    if (_currentBoss == null) return;

    final currentPhase = _currentBoss!.currentPhase;
    BossPhase? lastKnownPhase;

    if (lastKnownPhase != currentPhase) {
      _showPhaseChangeDialogue(currentPhase);
      lastKnownPhase = currentPhase;
    }
  }

  /// Shows dialogue for boss phase changes
  void _showPhaseChangeDialogue(BossPhase phase) {
    if (_dialogueManager == null) return;

    String message;
    switch (phase) {
      case BossPhase.tactical:
        message = "The Vampire Lord's tactics become more calculated and dangerous!";
        break;
      case BossPhase.desperate:
        message = "The wounded Vampire Lord enters a frenzied, desperate state!";
        break;
      case BossPhase.defeated:
        message = "The Vampire Lord staggers, its power finally fading...";
        break;
      default:
        return; // No message for aggressive phase
    }

    _dialogueManager!.showBossPhaseChange(message);
  }

  /// Checks for special boss events and abilities
  void _checkBossSpecialEvents(GhostCharacter player) {
    if (_currentBoss == null) return;

    // Check if boss used a special ability (this would be expanded with actual ability tracking)
    final distance = player.position.distanceTo(_currentBoss!.position);

    // Show warnings for dangerous situations
    if (distance <= 2 && _currentBoss!.currentPhase == BossPhase.desperate) {
      _dialogueManager?.showBossWarning(
        "Danger! The desperate Vampire Lord is extremely dangerous at close range!"
      );
    }
  }

  /// Handles boss combat with enhanced mechanics
  int processBossAttackOnPlayer(GhostCharacter player) {
    if (_currentBoss == null || !_currentBoss!.isAlive) return 0;

    final damage = _currentBoss!.attackPlayer(player);

    // Show boss attack message
    _showBossAttackMessage(damage);

    return damage;
  }

  /// Shows message when boss attacks player
  void _showBossAttackMessage(int damage) {
    if (_dialogueManager == null) return;

    final messages = [
      "The Vampire Lord's claws rake across you for $damage damage!",
      "Dark energy surges from the boss, dealing $damage damage!",
      "The Vampire Lord's fangs find their mark for $damage damage!",
      "Ancient vampire magic strikes you for $damage damage!",
    ];

    final randomIndex = DateTime.now().millisecondsSinceEpoch % messages.length;
    _dialogueManager!.showBossAttack(messages[randomIndex]);
  }

  /// Checks if player can use candy strategically against boss
  bool canUseCandyAgainstBoss(GhostCharacter player, CandyItem candy) {
    if (_currentBoss == null || !_encounterInitiated) return false;

    // Distance check - player must be close enough
    final distance = player.position.distanceTo(_currentBoss!.position);
    return distance <= 3; // Allow candy use within 3 tiles of boss
  }

  /// Processes candy use against boss (special strategic mechanics)
  bool useCandyAgainstBoss(GhostCharacter player, CandyItem candy) {
    if (!canUseCandyAgainstBoss(player, candy)) return false;

    // Different candy effects have special results against boss
    switch (candy.effect) {
      case CandyEffect.allyStrength:
        // Ally strength candy gives extra damage against boss
        _showCandyEffectMessage("Your strength candy empowers your allies against the Vampire Lord!");
        break;
      case CandyEffect.healthBoost:
        // Health candy is more effective during boss fight
        _showCandyEffectMessage("The healing candy glows with extra power near the boss!");
        break;
      case CandyEffect.speedIncrease:
        // Speed candy helps with boss positioning
        _showCandyEffectMessage("Your speed candy helps you evade the boss's attacks!");
        break;
      case CandyEffect.specialAbility:
        // Special ability candy has powerful effects against boss
        _showCandyEffectMessage("The special candy unleashes unexpected power against the boss!");
        break;
      case CandyEffect.maxHealthIncrease:
        // Max health candy provides lasting benefit
        _showCandyEffectMessage("The health candy provides lasting strength for the battle!");
        break;
      case CandyEffect.statModification:
        // Stat candy has general beneficial effects
        _showCandyEffectMessage("The powerful candy enhances your abilities against the boss!");
        break;
    }

    return true;
  }

  /// Shows message for candy effects against boss
  void _showCandyEffectMessage(String message) {
    if (_dialogueManager == null) return;
    _dialogueManager!.showCandyEffect(message);
  }

  /// Gets boss battle statistics
  Map<String, dynamic> getBossStats() {
    if (_currentBoss == null) {
      return {
        'hasBoss': false,
        'encounterInitiated': false,
        'bossDefeated': false,
      };
    }

    return {
      'hasBoss': true,
      'encounterInitiated': _encounterInitiated,
      'bossDefeated': _bossDefeated,
      'bossHealth': _currentBoss!.health,
      'bossMaxHealth': _currentBoss!.maxHealth,
      'bossHealthPercentage': _currentBoss!.healthPercentage,
      'bossPhase': _currentBoss!.currentPhase.name,
      'bossPosition': _currentBoss!.position.toString(),
      'bossIsAlive': _currentBoss!.isAlive,
      'bossAbilities': _currentBoss!.abilities.map((a) => a.name).toList(),
      'bossScale': 'using larger model',
    };
  }

  /// Forces boss encounter for testing
  void forceBossEncounter() {
    if (_currentBoss != null) {
      initiateBossEncounter();
    }
  }

  /// Resets boss manager to initial state
  void reset() {
    _currentBoss = null;
    _encounterInitiated = false;
    _bossDefeated = false;
    debugPrint('BossManager: Reset to initial state');
    notifyListeners();
  }

  @override
  String toString() {
    return 'BossManager(HasBoss: $hasBoss, Encountered: $_encounterInitiated, '
        'Defeated: $_bossDefeated, Phase: ${_currentBoss?.currentPhase.name ?? 'None'})';
  }
}