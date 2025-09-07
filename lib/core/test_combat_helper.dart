import 'dart:math';
import 'package:flutter/foundation.dart';

import 'enemy_character.dart';
import 'game_loop_manager.dart';
import 'position.dart';

/// Helper class for testing combat functionality
class TestCombatHelper {
  final GameLoopManager gameLoopManager;
  final Random _random = Random();

  TestCombatHelper({required this.gameLoopManager});

  /// Creates test allies around the player for combat testing
  Future<void> createTestAllies() async {
    if (gameLoopManager.ghostCharacter == null) {
      debugPrint('TestCombatHelper: No player character found');
      return;
    }

    final playerPos = gameLoopManager.ghostCharacter!.position;
    final alliesToCreate = 3;
    int created = 0;

    for (int i = 0; i < 20 && created < alliesToCreate; i++) {
      // Create positions around the player
      final dx = _random.nextInt(5) - 2; // -2 to +2
      final dz = _random.nextInt(5) - 2;
      final allyPos = Position(playerPos.x + dx, playerPos.z + dz);

      // Create a mock enemy to convert to ally
      final mockEnemy = EnemyCharacter(
        id: 'test_ally_$created',
        position: allyPos,
        modelPath: _getRandomHumanModel(),
      );

      // Convert to ally
      final success = await gameLoopManager.convertEnemyToAlly(mockEnemy);
      if (success) {
        created++;
        debugPrint('TestCombatHelper: Created test ally $created at $allyPos');
      }
    }

    debugPrint('TestCombatHelper: Created $created test allies');
  }

  /// Gets a random human model path for test allies
  String _getRandomHumanModel() {
    final models = [
      'assets/characters/character-male-a.obj',
      'assets/characters/character-male-b.obj',
      'assets/characters/character-female-a.obj',
      'assets/characters/character-female-b.obj',
    ];
    return models[_random.nextInt(models.length)];
  }

  /// Forces combat encounters by moving enemies closer to allies
  void forceCombatEncounters() {
    if (gameLoopManager.enemyManager == null) {
      debugPrint('TestCombatHelper: No enemy manager found');
      return;
    }

    final allies = gameLoopManager.allyManager.allies;
    final enemies = gameLoopManager.enemyManager!.activeEnemies;

    if (allies.isEmpty || enemies.isEmpty) {
      debugPrint('TestCombatHelper: No allies or enemies available for combat');
      return;
    }

    // Move some enemies close to allies to trigger combat
    int combatsForced = 0;
    for (
      int i = 0;
      i < min(allies.length, enemies.length) && combatsForced < 3;
      i++
    ) {
      final ally = allies[i];
      final enemy = enemies[i];

      if (enemy.isHostile && ally.isAlive) {
        // Move enemy to adjacent position to ally
        final newEnemyPos = Position(ally.position.x + 1, ally.position.z);

        enemy.moveTo(newEnemyPos);
        combatsForced++;

        debugPrint(
          'TestCombatHelper: Moved ${enemy.id} next to ${ally.id} to force combat',
        );
      }
    }

    if (combatsForced > 0) {
      debugPrint('TestCombatHelper: Forced $combatsForced combat encounters');
    }
  }

  /// Prints combat system status for debugging
  void printCombatStatus() {
    final stats = gameLoopManager.getGameStats();
    final allyInfo = gameLoopManager.getAllyInfo();

    debugPrint('=== Combat System Status ===');
    debugPrint('Game Loop Running: ${stats['isRunning']}');
    debugPrint('Total Allies: ${stats['totalAllies']}/${stats['maxAllies']}');
    debugPrint('Active Enemies: ${stats['activeEnemies']}');
    debugPrint('Active Combats: ${stats['activeCombats']}');
    debugPrint('Combats Processed: ${stats['combatsProcessed']}');
    debugPrint('Enemies Defeated: ${stats['enemiesDefeated']}');
    debugPrint('Allies Lost: ${stats['alliesLost']}');
    debugPrint('Player Position: ${stats['playerPosition']}');

    if (allyInfo['total'] > 0) {
      debugPrint('Ally Details:');
      debugPrint('  - In Combat: ${allyInfo['inCombat']}');
      debugPrint('  - Following: ${allyInfo['following']}');
      debugPrint(
        '  - Average Satisfaction: ${(allyInfo['averageSatisfaction'] * 100).toStringAsFixed(1)}%',
      );
      debugPrint(
        '  - Total Combat Strength: ${allyInfo['totalCombatStrength']}',
      );
    }
    debugPrint('========================');
  }

  /// Runs a complete combat test sequence
  Future<void> runCombatTest() async {
    debugPrint('TestCombatHelper: Starting combat test sequence...');

    // Step 1: Create test allies
    await createTestAllies();
    await Future.delayed(const Duration(seconds: 1));

    // Step 2: Print initial status
    printCombatStatus();
    await Future.delayed(const Duration(seconds: 1));

    // Step 3: Force combat encounters
    forceCombatEncounters();
    await Future.delayed(const Duration(seconds: 2));

    // Step 4: Print combat results
    printCombatStatus();

    debugPrint('TestCombatHelper: Combat test sequence completed');
  }
}
