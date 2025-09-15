import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ally_character.dart';
import 'ally_manager.dart';
import 'animation_phase_manager.dart';
import 'boss_character.dart';
import 'boss_manager.dart';
import 'combat_manager.dart';
import 'victory_manager.dart';
import 'enemy_character.dart';
import 'enemy_manager.dart';
import 'ghost_character.dart';
import 'gift_system.dart';
import 'player_combat_result.dart';
import 'position.dart';
import 'tile_map.dart';
import 'dialogue_manager.dart';
import 'candy_collection_system.dart';
import 'collection_feedback.dart';
import 'candy_item.dart';
import 'combat_feedback_system.dart';
import '../l10n/strings.g.dart';

/// Manages the main game loop and coordinates all game systems
class GameLoopManager extends ChangeNotifier {
  /// The ghost character (player)
  GhostCharacter? _ghostCharacter;

  /// Enemy manager
  EnemyManager? _enemyManager;

  /// Ally manager
  final AllyManager _allyManager = AllyManager(maxAllies: 10);

  /// Boss manager
  final BossManager _bossManager = BossManager();

  /// Victory manager
  final VictoryManager _victoryManager = VictoryManager();

  /// Combat manager
  final CombatManager _combatManager = CombatManager();

  /// Combat feedback system
  final CombatFeedbackSystem _combatFeedbackSystem = CombatFeedbackSystem();

  /// Gift system manager
  final GiftSystem _giftSystem = GiftSystem();

  /// Animation phase manager
  final AnimationPhaseManager _animationManager = AnimationPhaseManager();

  /// Reference to the tile map
  TileMap? _tileMap;

  /// Reference to dialogue manager for combat messages
  DialogueManager? _dialogueManager;

  /// Reference to candy collection system
  CandyCollectionSystem? _candyCollectionSystem;

  /// Reference to collection feedback manager
  CollectionFeedbackManager? _collectionFeedbackManager;

  /// Reference to scene manager for movement animations
  Future<void> Function()? _onMovementAnimation;

  /// Callback for animating enemy movement
  Future<void> Function(String, Position, Position)? _onAnimateEnemyMovement;

  /// Callback for animating ally movement
  Future<void> Function(String, Position, Position)? _onAnimateAllyMovement;

  /// Callback for when an enemy is defeated and should be removed from scene
  Function(String enemyId)? _onEnemyDefeated;

  /// Callback for when candy is collected and should be removed from scene
  Function(Position position)? _onCandyCollected;

  /// Callback for when the game is won (boss defeated)
  VoidCallback? onVictory;

  /// Callback for when the game is lost (player defeated)
  VoidCallback? onDefeat;

  /// Whether the turn-based system is running
  bool _isRunning = false;

  /// Combat statistics
  int _totalCombatsProcessed = 0;
  int _enemiesDefeated = 0;
  int _alliesLost = 0;
  int _playerEnemiesDefeated = 0;

  /// Gift statistics
  int _candiesGiven = 0;

  /// Recent combat results for UI feedback
  final List<PlayerCombatResult> _recentPlayerCombats = [];
  static const int maxRecentCombats = 5;

  /// Getters for accessing managers
  AllyManager get allyManager => _allyManager;
  BossManager get bossManager => _bossManager;
  VictoryManager get victoryManager => _victoryManager;
  CombatManager get combatManager => _combatManager;
  CombatFeedbackSystem get combatFeedbackSystem => _combatFeedbackSystem;
  GiftSystem get giftSystem => _giftSystem;
  AnimationPhaseManager get animationManager => _animationManager;
  EnemyManager? get enemyManager => _enemyManager;
  GhostCharacter? get ghostCharacter => _ghostCharacter;

  /// Combat statistics getters
  int get totalCombatsProcessed => _totalCombatsProcessed;
  int get enemiesDefeated => _enemiesDefeated;
  int get alliesLost => _alliesLost;
  int get playerEnemiesDefeated => _playerEnemiesDefeated;

  /// Gift statistics getters
  int get candiesGiven => _candiesGiven;

  /// Recent combat results getter
  List<PlayerCombatResult> get recentPlayerCombats =>
      List.unmodifiable(_recentPlayerCombats);

  /// Get the number of enemies defeated (public method for external access)
  int getEnemiesDefeatedCount() => _enemiesDefeated;

  /// Initializes the game loop with required components
  void initialize({
    required GhostCharacter ghostCharacter,
    required EnemyManager enemyManager,
    required TileMap tileMap,
    DialogueManager? dialogueManager,
    CandyCollectionSystem? candyCollectionSystem,
    CollectionFeedbackManager? collectionFeedbackManager,
    Function(String enemyId)? onEnemyDefeated,
    Function(Position position)? onCandyCollected,
    Future<void> Function()? onMovementAnimation,
    Future<void> Function(String, Position, Position)? onAnimateEnemyMovement,
    Future<void> Function(String, Position, Position)? onAnimateAllyMovement,
  }) {
    _ghostCharacter = ghostCharacter;
    _enemyManager = enemyManager;
    _tileMap = tileMap;
    _dialogueManager = dialogueManager;
    _candyCollectionSystem = candyCollectionSystem;
    _collectionFeedbackManager = collectionFeedbackManager;
    _onEnemyDefeated = onEnemyDefeated;
    _onCandyCollected = onCandyCollected;
    _onMovementAnimation = onMovementAnimation;
    _onAnimateEnemyMovement = onAnimateEnemyMovement;
    _onAnimateAllyMovement = onAnimateAllyMovement;

    // Set player reference for ally manager
    _allyManager.setPlayer(ghostCharacter);

    // Initialize victory manager
    _victoryManager.initialize(
      dialogueManager: dialogueManager,
      bossManager: _bossManager,
      onVictory: () {
        debugPrint('GameLoopManager: Victory achieved!');
        onVictory?.call();
      },
      onGameComplete: () => debugPrint('GameLoopManager: Game completed!'),
    );

    // Initialize boss manager
    _bossManager.initialize(
      dialogueManager: dialogueManager,
      enemyManager: enemyManager,
      onVictory: () => _victoryManager.checkVictoryConditions(ghostCharacter),
      onBossEncounterStart: () => debugPrint('GameLoopManager: Boss encounter started!'),
      onBossDefeated: () => _victoryManager.checkVictoryConditions(ghostCharacter),
    );

    debugPrint(
      'GameLoopManager: Initialized with player at ${ghostCharacter.position}',
    );
  }

  /// Initializes the turn-based game system (no real-time loop)
  void initializeTurnBasedSystem() {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint('GameLoopManager: Turn-based system initialized');
    notifyListeners();
  }

  /// Stops the turn-based system
  void stopTurnBasedSystem() {
    if (!_isRunning) return;

    _isRunning = false;
    debugPrint('GameLoopManager: Turn-based system stopped');
    notifyListeners();
  }

  /// Gets all hostile enemies in the game
  List<EnemyCharacter> _getHostileEnemies() {
    if (_enemyManager == null) return [];

    return _enemyManager!.activeEnemies
        .where((enemy) => enemy.isHostile && enemy.isAlive)
        .toList();
  }

  /// Processes combat between allies and hostile enemies
  void _processCombat(List<EnemyCharacter> hostileEnemies) {
    final allies = _allyManager.allies.where((ally) => ally.isAlive).toList();

    if (allies.isEmpty || hostileEnemies.isEmpty) {
      return;
    }

    // Separate boss from regular enemies
    final boss = hostileEnemies.whereType<BossCharacter>().firstOrNull;
    final regularEnemies = hostileEnemies.where((enemy) => enemy is! BossCharacter).toList();

    // Process regular combat encounters
    if (regularEnemies.isNotEmpty) {
      final combatResults = _combatManager.processCombat(allies, regularEnemies);

      if (combatResults.isNotEmpty) {
        _totalCombatsProcessed += combatResults.length;

        for (final result in combatResults) {
          _processCombatResult(result);
        }

        debugPrint(
          'GameLoopManager: Processed ${combatResults.length} regular combat encounters',
        );
      }
    }

    // Process boss combat separately with enhanced mechanics
    if (boss != null && boss.isAlive && !boss.isDefeated) {
      final bossCombatResults = _combatManager.processBossCombat(allies, boss);

      if (bossCombatResults.isNotEmpty) {
        _totalCombatsProcessed += bossCombatResults.length;

        for (final result in bossCombatResults) {
          _processBossCombatResult(result);
        }

        debugPrint(
          'GameLoopManager: Processed ${bossCombatResults.length} BOSS combat encounters',
        );
      }
    }
  }

  /// Processes the result of a single combat encounter
  void _processCombatResult(CombatResult result) {
    // Generate combat feedback messages
    final feedbackMessages = _combatFeedbackSystem.generateCombatFeedback([
      result,
    ]);

    // Display each combat feedback message through dialogue manager
    for (final feedbackMessage in feedbackMessages) {
      if (_dialogueManager != null) {
        _dialogueManager!.showCombatFeedback(feedbackMessage.text);
      }
    }

    if (result.enemyDefeated) {
      _enemiesDefeated++;
      _handleEnemyDefeated(result.enemy);

      // Generate additional feedback for enemy defeated
      final enemyDefeatedFeedback = _combatFeedbackSystem
          .generateEnemyDefeatedFeedback(result.enemy);
      if (_dialogueManager != null) {
        _dialogueManager!.showCombatFeedback(enemyDefeatedFeedback.text);
      }
    }

    if (result.allyDefeated) {
      _alliesLost++;
    }

    // Log significant combat events
    if (result.enemyDefeated || result.allyDefeated) {
      debugPrint('GameLoopManager: Combat result - ${result.description}');
    }
  }

  /// Processes the result of a boss combat encounter with special handling
  void _processBossCombatResult(CombatResult result) {
    // Show special boss combat messages
    if (result.enemyDefeated && result.enemy is BossCharacter) {
      final boss = result.enemy as BossCharacter;
      if (_dialogueManager != null) {
        _dialogueManager!.showBossAttack(
          '${result.ally.id} delivers a devastating blow to the Vampire Lord for ${result.allyDamageDealt} damage!'
        );
        if (boss.isDefeated) {
          _dialogueManager!.showBossAttack(
            'The mighty Vampire Lord has been defeated by ${result.ally.id}!'
          );
        }
      }
      _enemiesDefeated++;
      _handleEnemyDefeated(boss);
    } else if (result.allyDefeated) {
      if (_dialogueManager != null) {
        _dialogueManager!.showBossAttack(
          'The Vampire Lord crushes ${result.ally.id} with ${result.enemyDamageDealt} damage!'
        );
      }
      _alliesLost++;
    } else {
      // Ongoing boss combat
      if (_dialogueManager != null) {
        _dialogueManager!.showCombatFeedback(
          'Epic battle: ${result.ally.id} deals ${result.allyDamageDealt} damage, '
          'Vampire Lord retaliates for ${result.enemyDamageDealt} damage!'
        );
      }
    }

    // Log boss combat events
    debugPrint('GameLoopManager: BOSS Combat result - ${result.description}');
  }

  /// Handles when an enemy is defeated in combat
  void _handleEnemyDefeated(EnemyCharacter enemy) {
    // Remove enemy from the enemy manager
    if (_enemyManager != null) {
      _enemyManager!.removeEnemy(enemy.id);
    }

    // Remove enemy from the scene manager (3D model)
    if (_onEnemyDefeated != null) {
      _onEnemyDefeated!(enemy.id);
    }

    debugPrint('GameLoopManager: Enemy ${enemy.id} defeated and removed');
  }

  /// Handles ally state changes and generates appropriate feedback
  void _handleAllyStateChange(
    AllyCharacter ally,
    AllyState previousState,
    AllyState newState,
  ) {
    // Generate feedback for ally state change
    final stateChangeFeedback = _combatFeedbackSystem
        .generateAllyStateChangeFeedback(ally, previousState, newState);

    if (stateChangeFeedback != null && _dialogueManager != null) {
      _dialogueManager!.showCombatFeedback(stateChangeFeedback.text);
    }

    debugPrint(
      'GameLoopManager: Ally ${ally.id} state changed from ${previousState.name} to ${newState.name}',
    );
  }

  /// Cleans up satisfied enemies from the game
  void _cleanupSatisfiedEnemies() {
    if (_enemyManager == null) return;

    final satisfiedEnemies = _enemyManager!.enemies.values
        .where((enemy) => enemy.isSatisfied)
        .toList();

    for (final enemy in satisfiedEnemies) {
      _handleEnemyDefeated(enemy);
      debugPrint('GameLoopManager: Cleaned up satisfied enemy ${enemy.id}');
    }
  }

  /// Processes direct combat between player and enemies
  void _processPlayerCombat() {
    if (_ghostCharacter == null || _enemyManager == null) return;

    // Check for directional attacks first (from input processing)
    final playerAttackResult = _ghostCharacter!.consumeLastAttackResult();
    if (playerAttackResult != null) {
      _addPlayerCombatResult(playerAttackResult);

      // Show combat message for player attack
      _showPlayerAttackMessage(playerAttackResult);

      if (playerAttackResult.enemyDefeated) {
        _playerEnemiesDefeated++;
        // Find and remove the defeated enemy
        final defeatedEnemies = _enemyManager!.activeEnemies
            .where((enemy) => !enemy.isAlive || enemy.health <= 0)
            .toList();
        for (final enemy in defeatedEnemies) {
          _handleEnemyDefeated(enemy);
        }
        debugPrint(
          'GameLoopManager: Player defeated enemy with directional attack',
        );
      }
    }

    // Process adjacent combat (both as counter-attack after directional attack and standalone)
    final playerPos = _ghostCharacter!.position;
    final adjacentEnemies = _enemyManager!.activeEnemies.where((enemy) {
      return playerPos.distanceTo(enemy.position) == 1 &&
          enemy.isHostile &&
          enemy.isAlive;
    }).toList();

    if (adjacentEnemies.isEmpty) return;

    debugPrint(
      'GameLoopManager: Processing adjacent combat with ${adjacentEnemies.length} enemies',
    );

    for (final enemy in adjacentEnemies) {
      // Enemy attacks player (either as counter-attack or standalone)
      final enemyDamage = enemy.attackPlayer(_ghostCharacter!);
      _ghostCharacter!.takeDamageFromEnemy(enemyDamage, enemy);

      // Show message for enemy attacking player
      _showEnemyAttackMessage(enemy, enemyDamage);

      debugPrint(
        'GameLoopManager: ${enemy.id} attacks player for $enemyDamage damage',
      );

      // Check if player was defeated
      if (!_ghostCharacter!.isAlive) {
        debugPrint('GameLoopManager: Player was defeated!');
        // Trigger game over with defeat
        onDefeat?.call();
        break;
      }
    }
  }

  /// Adds a player combat result to recent history
  void _addPlayerCombatResult(PlayerCombatResult result) {
    _recentPlayerCombats.add(result);

    // Keep only recent results
    while (_recentPlayerCombats.length > maxRecentCombats) {
      _recentPlayerCombats.removeAt(0);
    }
  }

  /// Called when the player character moves - processes one turn
  Future<void> onPlayerMoved() async {
    if (_ghostCharacter == null || _enemyManager == null || _tileMap == null) {
      return;
    }

    debugPrint('GameLoopManager: Processing turn after player move');

    try {
      // Clear events from previous turn and notify dialogue manager of new turn
      if (_dialogueManager != null) {
        _dialogueManager!.clearTurnEvents();
        _dialogueManager!.onNewTurn();
      }

      // Animation Phase 1: Player Movement Animation
      await _animationManager.playMovementAnimation(
        onMovementAnimation: _onMovementAnimation,
      );

      // Process candy collection after movement animation
      _processCandyCollection();

      // Update enemy activation based on new player position
      _enemyManager!.updateEnemyActivation(_ghostCharacter!.position);

      // Check for boss encounter
      _bossManager.checkBossEncounter(_ghostCharacter!.position);

      // Animation Phase 2: Enemy AI Movement
      await _animationManager.playAIMovementAnimation();

      // Process enemy AI (one turn)
      await _enemyManager!.processEnemyAI(
        _ghostCharacter!,
        _onAnimateEnemyMovement,
      );

      // Animation Phase 3: Combat Animation
      await _animationManager.playCombatAnimation();

      // Process player vs enemy combat
      _processPlayerCombat();

      // Get all active hostile enemies (after player combat)
      final hostileEnemies = _getHostileEnemies();

      // Animation Phase 4: Ally Movement Animation
      await _animationManager.playAllyMovementAnimation();

      // Update ally AI (one turn)
      await _allyManager.updateAllies(
        _tileMap!,
        hostileEnemies,
        onAnimateMovement: _onAnimateAllyMovement,
        onStateChange: _handleAllyStateChange,
      );

      // Process combat between allies and hostile enemies
      _processCombat(hostileEnemies);

      // Animation Phase 5: Effects Animation (cleanup, status changes)
      await _animationManager.playEffectsAnimation();

      // Clean up satisfied enemies
      _cleanupSatisfiedEnemies();

      // Process boss turn (check victory conditions, phase changes, etc.)
      _bossManager.processBossTurn(_ghostCharacter!);

      // Check victory conditions
      _victoryManager.checkVictoryConditions(_ghostCharacter!);

      // Notify listeners of updates
      notifyListeners();

      debugPrint('GameLoopManager: Turn completed');
    } catch (e) {
      debugPrint('GameLoopManager: Error in turn processing: $e');
    }
  }

  /// Converts an enemy to an ally through the gift system
  Future<bool> convertEnemyToAlly(EnemyCharacter enemy) async {
    if (!_allyManager.isAtMaxCapacity) {
      final success = await _allyManager.convertEnemyToAlly(enemy);
      if (success && _enemyManager != null) {
        // Remove enemy from enemy manager
        _enemyManager!.removeEnemy(enemy.id);

        // Remove enemy from the scene manager (3D model)
        if (_onEnemyDefeated != null) {
          _onEnemyDefeated!(enemy.id);
        }

        // Show dialogue message
        if (_dialogueManager != null) {
          _dialogueManager!.showCombatFeedback(
            '${enemy.id} has become your ally!',
          );
        }

        debugPrint(
          'GameLoopManager: Enemy ${enemy.id} converted to ally and model loaded',
        );
        return true;
      }
    }
    return false;
  }

  /// Initiates the gift process with an adjacent enemy
  bool initiateGiftToEnemy(EnemyCharacter enemy) {
    if (_ghostCharacter == null) return false;

    return _giftSystem.initiateGift(_ghostCharacter!, enemy);
  }

  /// Confirms the gift and completes the enemy conversion
  bool confirmGift() {
    if (_ghostCharacter == null) return false;

    final targetEnemy = _giftSystem.targetEnemy;
    final success = _giftSystem.confirmGift(_ghostCharacter!);

    if (success && targetEnemy != null) {
      // Increment candies given counter
      _candiesGiven++;
      debugPrint('GameLoopManager: Candy given! Total candies given: $_candiesGiven');

      // Convert the target enemy to ally
      convertEnemyToAlly(targetEnemy);
    }
    return success;
  }

  /// Cancels the current gift process
  void cancelGift() {
    _giftSystem.cancelGift();
  }

  /// Gets all adjacent enemies that can receive gifts
  List<EnemyCharacter> getAdjacentGiftableEnemies() {
    if (_ghostCharacter == null || _enemyManager == null) return [];

    final allEnemies = _enemyManager!.activeEnemies;
    return _giftSystem.getAdjacentGiftableEnemies(_ghostCharacter!, allEnemies);
  }

  /// Checks if the player can give gifts to any adjacent enemies
  bool canGiveGifts() {
    if (_ghostCharacter == null || _enemyManager == null) return false;

    final allEnemies = _enemyManager!.activeEnemies;
    return _giftSystem.canGiveGifts(_ghostCharacter!, allEnemies);
  }

  /// Gets game statistics
  Map<String, dynamic> getGameStats() {
    return {
      'isRunning': _isRunning,
      'totalAllies': _allyManager.count,
      'maxAllies': _allyManager.maxAllies,
      'activeEnemies': _enemyManager?.activeEnemyCount ?? 0,
      'totalEnemies': _enemyManager?.enemyCount ?? 0,
      'activeCombats': _combatManager.activeCombats.length,
      'combatsProcessed': _totalCombatsProcessed,
      'enemiesDefeated': _enemiesDefeated,
      'alliesLost': _alliesLost,
      'playerEnemiesDefeated': _playerEnemiesDefeated,
      'playerHealth': _ghostCharacter?.health ?? 0,
      'playerMaxHealth': _ghostCharacter?.maxHealth ?? 100,
      'playerCombatStrength': _ghostCharacter?.effectiveCombatStrength ?? 0,
      'playerPosition': _ghostCharacter?.position.toString() ?? 'Unknown',
    };
  }

  /// Gets detailed ally information
  Map<String, dynamic> getAllyInfo() {
    return _allyManager.getAllySummary();
  }

  /// Forces a manual turn processing (useful for debugging)
  Future<void> forceTurn() async {
    if (_isRunning) {
      await onPlayerMoved();
    }
  }

  /// Shows comical message when player attacks enemy
  void _showPlayerAttackMessage(PlayerCombatResult result) {
    if (_dialogueManager == null) return;

    final damage = result.playerDamageDealt;
    final messages = result.enemyDefeated
        ? t.combat.playerAttacks.withDamage
        : t.combat.playerAttacks.withoutDamage;

    final randomIndex = DateTime.now().millisecondsSinceEpoch % messages.length;
    final messageTemplate = messages[randomIndex];
    final formattedMessage = messageTemplate.replaceAll(
      '{}',
      damage.toString(),
    );

    _dialogueManager!.showPlayerAttack(formattedMessage);
  }

  /// Shows comical message when enemy attacks player
  void _showEnemyAttackMessage(EnemyCharacter enemy, int damage) {
    if (_dialogueManager == null) return;

    final enemyType = enemy.enemyType.displayName;
    final messages = damage > 0
        ? t.combat.enemyAttacks.withDamage
        : t.combat.enemyAttacks.withoutDamage;

    final randomIndex = DateTime.now().millisecondsSinceEpoch % messages.length;
    final messageTemplate = messages[randomIndex];

    String formattedMessage;
    if (damage > 0) {
      // Replace first {} with enemy type, second {} with damage
      formattedMessage = messageTemplate
          .replaceFirst('{}', enemyType)
          .replaceFirst('{}', damage.toString());
    } else {
      // Replace {} with enemy type
      formattedMessage = messageTemplate.replaceAll('{}', enemyType);
    }

    _dialogueManager!.showCombatFeedback(formattedMessage);
  }

  /// Processes candy collection at the player's current position
  void _processCandyCollection() {
    if (_ghostCharacter == null ||
        _candyCollectionSystem == null ||
        _tileMap == null) {
      return;
    }

    // Use the candy collection system to process movement
    final collectionEvent = _candyCollectionSystem!.processMovement(
      _ghostCharacter!,
      _tileMap!,
    );

    if (collectionEvent != null) {
      // Handle the collection event
      _handleCandyCollectionEvent(collectionEvent);
    }
  }

  /// Handles a candy collection event with proper feedback and scene updates
  void _handleCandyCollectionEvent(CandyCollectionEvent event) {
    if (event.successful) {
      // Show candy collection message using dialogue manager
      _showCandyCollectionMessage(event.candy);

      // Process visual feedback
      if (_collectionFeedbackManager != null) {
        _collectionFeedbackManager!.processCollectionEvent(event);
      }

      // Remove candy from scene (tile map and 3D object)
      if (_onCandyCollected != null) {
        _onCandyCollected!(event.position);
      }

      debugPrint(
        'GameLoopManager: Candy collected: ${event.candy.name} at ${event.position}',
      );
    } else {
      // Show inventory full message
      _showInventoryFullMessage();

      // Process failure feedback
      if (_collectionFeedbackManager != null) {
        _collectionFeedbackManager!.processCollectionEvent(event);
      }
    }
  }

  /// Shows a candy collection message with variety
  void _showCandyCollectionMessage(CandyItem candy) {
    if (_dialogueManager == null) return;

    final messages = t.candyCollection.messages;
    final random = (DateTime.now().millisecondsSinceEpoch % messages.length);
    final message = messages[random]
        .replaceAll('{name}', candy.name)
        .replaceAll('{description}', candy.description);

    _dialogueManager!.showItemCollection(message);
  }

  /// Shows a message when inventory is full
  void _showInventoryFullMessage() {
    if (_dialogueManager == null) return;

    _dialogueManager!.showItemCollection(
      t.candyCollection.inventoryFullMessage,
    );
  }

  /// Spawns the boss at the end of the main path
  Future<void> spawnBoss(Position bossLocation) async {
    await _bossManager.spawnBoss(bossLocation);
    debugPrint('GameLoopManager: Boss spawned at $bossLocation');
  }

  /// Checks if player can use candy against the boss
  bool canUseCandyAgainstBoss(CandyItem candy) {
    if (_ghostCharacter == null) return false;
    return _bossManager.canUseCandyAgainstBoss(_ghostCharacter!, candy);
  }

  /// Uses candy strategically against the boss
  bool useCandyAgainstBoss(CandyItem candy) {
    if (_ghostCharacter == null) return false;
    return _bossManager.useCandyAgainstBoss(_ghostCharacter!, candy);
  }

  /// Gets boss battle statistics
  Map<String, dynamic> getBossStats() {
    return _bossManager.getBossStats();
  }

  /// Gets victory progress and status
  Map<String, dynamic> getVictoryProgress() {
    return _victoryManager.getVictoryProgress();
  }

  /// Forces victory for testing purposes
  void forceVictory() {
    if (_ghostCharacter != null) {
      _victoryManager.forceVictory(_ghostCharacter!);
    }
  }

  /// Checks if the game has been won
  bool get gameWon => _victoryManager.gameWon;

  /// Checks if victory has been triggered
  bool get victoryTriggered => _victoryManager.victoryTriggered;

  @override
  void dispose() {
    stopTurnBasedSystem();
    _allyManager.dispose();
    _animationManager.dispose();
    super.dispose();
  }

  @override
  String toString() {
    final stats = getGameStats();
    return 'GameLoopManager(Running: ${stats['isRunning']}, '
        'Allies: ${stats['totalAllies']}/${stats['maxAllies']}, '
        'Enemies: ${stats['activeEnemies']}/${stats['totalEnemies']}, '
        'Combats: ${stats['activeCombats']})';
  }
}
