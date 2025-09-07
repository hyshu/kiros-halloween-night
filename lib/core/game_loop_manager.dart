import 'package:flutter/foundation.dart';

import 'ally_character.dart';
import 'ally_manager.dart';
import 'combat_manager.dart';
import 'enemy_character.dart';
import 'enemy_manager.dart';
import 'ghost_character.dart';
import 'player_combat_result.dart';
import 'tile_map.dart';
import 'dialogue_manager.dart';
import '../l10n/strings.g.dart';

/// Manages the main game loop and coordinates all game systems
class GameLoopManager extends ChangeNotifier {
  /// The ghost character (player)
  GhostCharacter? _ghostCharacter;

  /// Enemy manager
  EnemyManager? _enemyManager;

  /// Ally manager
  final AllyManager _allyManager = AllyManager(maxAllies: 10);

  /// Combat manager
  final CombatManager _combatManager = CombatManager();

  /// Reference to the tile map
  TileMap? _tileMap;

  /// Reference to dialogue manager for combat messages
  DialogueManager? _dialogueManager;

  /// Whether the turn-based system is running
  bool _isRunning = false;

  /// Combat statistics
  int _totalCombatsProcessed = 0;
  int _enemiesDefeated = 0;
  int _alliesLost = 0;
  int _playerEnemiesDefeated = 0;

  /// Recent combat results for UI feedback
  final List<PlayerCombatResult> _recentPlayerCombats = [];
  static const int maxRecentCombats = 5;

  /// Getters for accessing managers
  AllyManager get allyManager => _allyManager;
  CombatManager get combatManager => _combatManager;
  EnemyManager? get enemyManager => _enemyManager;
  GhostCharacter? get ghostCharacter => _ghostCharacter;

  /// Combat statistics getters
  int get totalCombatsProcessed => _totalCombatsProcessed;
  int get enemiesDefeated => _enemiesDefeated;
  int get alliesLost => _alliesLost;
  int get playerEnemiesDefeated => _playerEnemiesDefeated;

  /// Recent combat results getter
  List<PlayerCombatResult> get recentPlayerCombats =>
      List.unmodifiable(_recentPlayerCombats);

  /// Initializes the game loop with required components
  void initialize({
    required GhostCharacter ghostCharacter,
    required EnemyManager enemyManager,
    required TileMap tileMap,
    DialogueManager? dialogueManager,
  }) {
    _ghostCharacter = ghostCharacter;
    _enemyManager = enemyManager;
    _tileMap = tileMap;
    _dialogueManager = dialogueManager;

    // Set player reference for ally manager
    _allyManager.setPlayer(ghostCharacter);

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

    // Process combat encounters
    final combatResults = _combatManager.processCombat(allies, hostileEnemies);

    if (combatResults.isNotEmpty) {
      _totalCombatsProcessed += combatResults.length;

      for (final result in combatResults) {
        _processCombatResult(result);
      }

      debugPrint(
        'GameLoopManager: Processed ${combatResults.length} combat encounters',
      );
    }
  }

  /// Processes the result of a single combat encounter
  void _processCombatResult(CombatResult result) {
    if (result.enemyDefeated) {
      _enemiesDefeated++;
      _handleEnemyDefeated(result.enemy);
    }

    if (result.allyDefeated) {
      _alliesLost++;
      _handleAllyDefeated(result.ally);
    }

    // Log significant combat events
    if (result.enemyDefeated || result.allyDefeated) {
      debugPrint('GameLoopManager: Combat result - ${result.description}');
    }
  }

  /// Handles when an enemy is defeated in combat
  void _handleEnemyDefeated(EnemyCharacter enemy) {
    // Remove enemy from the scene
    if (_enemyManager != null) {
      _enemyManager!.removeEnemy(enemy.id);
    }

    debugPrint('GameLoopManager: Enemy ${enemy.id} defeated and removed');
  }

  /// Handles when an ally is defeated in combat
  void _handleAllyDefeated(AllyCharacter ally) {
    // Ally will be automatically removed by AllyManager
    debugPrint('GameLoopManager: Ally ${ally.id} defeated');
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
          _enemyManager!.removeEnemy(enemy.id);
        }
        debugPrint(
          'GameLoopManager: Player defeated enemy with directional attack',
        );
      }
      return; // Directional attack processed, no adjacent combat
    }

    // Legacy adjacent combat (in case of multiple adjacent enemies)
    final playerPos = _ghostCharacter!.position;
    final adjacentEnemies = _enemyManager!.activeEnemies.where((enemy) {
      return playerPos.distanceTo(enemy.position) == 1 && enemy.isHostile;
    }).toList();

    if (adjacentEnemies.isEmpty) return;

    debugPrint(
      'GameLoopManager: Processing adjacent combat with ${adjacentEnemies.length} enemies',
    );

    for (final enemy in adjacentEnemies) {
      // Enemy attacks player (since player didn't initiate directional attack)
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
        // TODO: Handle player death
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
  void onPlayerMoved() {
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
      // Update enemy activation based on new player position
      _enemyManager!.updateEnemyActivation(_ghostCharacter!.position);

      // Process enemy AI (one turn)
      _enemyManager!.processEnemyAI(_ghostCharacter!);

      // Process player vs enemy combat
      _processPlayerCombat();

      // Get all active hostile enemies (after player combat)
      final hostileEnemies = _getHostileEnemies();

      // Update ally AI (one turn)
      _allyManager.updateAllies(_tileMap!, hostileEnemies);

      // Process combat between allies and hostile enemies
      _processCombat(hostileEnemies);

      // Notify listeners of updates
      notifyListeners();

      debugPrint('GameLoopManager: Turn completed');
    } catch (e) {
      debugPrint('GameLoopManager: Error in turn processing: $e');
    }
  }

  /// Converts an enemy to an ally (for future integration)
  bool convertEnemyToAlly(EnemyCharacter enemy) {
    if (!_allyManager.isAtMaxCapacity) {
      final success = _allyManager.convertEnemyToAlly(enemy);
      if (success && _enemyManager != null) {
        // Remove enemy from enemy manager
        _enemyManager!.removeEnemy(enemy.id);
        debugPrint('GameLoopManager: Converted enemy ${enemy.id} to ally');
        return true;
      }
    }
    return false;
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
  void forceTurn() {
    if (_isRunning) {
      onPlayerMoved();
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

  @override
  void dispose() {
    stopTurnBasedSystem();
    _allyManager.dispose();
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
