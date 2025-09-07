import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/ally_manager.dart';
import 'package:kiro_halloween_game/core/ally_character.dart';
import 'package:kiro_halloween_game/core/enemy_character.dart';
import 'package:kiro_halloween_game/core/ghost_character.dart';
import 'package:kiro_halloween_game/core/position.dart';
import 'package:kiro_halloween_game/core/tile_map.dart';
import 'package:kiro_halloween_game/core/enemy_spawner.dart';

void main() {
  group('AllyManager', () {
    late AllyManager allyManager;
    late GhostCharacter player;
    late EnemyCharacter enemy;
    late TileMap tileMap;

    setUp(() {
      allyManager = AllyManager(maxAllies: 5);
      player = GhostCharacter(id: 'player', position: Position(5, 5));
      enemy = EnemyCharacter.human(
        id: 'enemy1',
        position: Position(6, 6),
        modelType: HumanModelType.maleA,
      );
      tileMap = TileMap();
      allyManager.setPlayer(player);
    });

    test('should initialize with correct default state', () {
      expect(allyManager.count, 0);
      expect(allyManager.allies, isEmpty);
      expect(allyManager.maxAllies, 5);
      expect(allyManager.isAtMaxCapacity, false);
      expect(allyManager.remainingCapacity, 5);
    });

    test('should set player and update existing allies', () {
      // First convert an enemy to ally
      allyManager.convertEnemyToAlly(enemy);

      final newPlayer = GhostCharacter(
        id: 'player2',
        position: Position(10, 10),
      );

      allyManager.setPlayer(newPlayer);

      // All allies should now follow the new player
      for (final ally in allyManager.allies) {
        expect(ally.followTarget, newPlayer);
      }
    });

    test('should successfully convert enemy to ally', () {
      final success = allyManager.convertEnemyToAlly(enemy);

      expect(success, true);
      expect(allyManager.count, 1);
      expect(allyManager.allies.first.originalEnemy, enemy);
      expect(allyManager.allies.first.followTarget, player);
    });

    test('should fail to convert enemy when at max capacity', () {
      // Fill up to max capacity
      for (int i = 0; i < 5; i++) {
        final testEnemy = EnemyCharacter.human(
          id: 'enemy$i',
          position: Position(i, i),
          modelType: HumanModelType.maleA,
        );
        allyManager.convertEnemyToAlly(testEnemy);
      }

      expect(allyManager.isAtMaxCapacity, true);

      final newEnemy = EnemyCharacter.human(
        id: 'enemy_extra',
        position: Position(10, 10),
        modelType: HumanModelType.femaleA,
      );

      final success = allyManager.convertEnemyToAlly(newEnemy);

      expect(success, false);
      expect(allyManager.count, 5);
    });

    test('should remove ally successfully', () {
      allyManager.convertEnemyToAlly(enemy);
      final ally = allyManager.allies.first;

      final success = allyManager.removeAlly(ally);

      expect(success, true);
      expect(allyManager.count, 0);
      expect(allyManager.allies, isEmpty);
    });

    test('should remove ally by ID', () {
      allyManager.convertEnemyToAlly(enemy);
      final allyId = allyManager.allies.first.id;

      final success = allyManager.removeAllyById(allyId);

      expect(success, true);
      expect(allyManager.count, 0);
    });

    test('should fail to remove non-existent ally', () {
      final success = allyManager.removeAllyById('non_existent');

      expect(success, false);
    });

    test('should get ally by ID', () {
      allyManager.convertEnemyToAlly(enemy);
      final ally = allyManager.allies.first;

      final foundAlly = allyManager.getAllyById(ally.id);

      expect(foundAlly, ally);
    });

    test('should return null for non-existent ally ID', () {
      final foundAlly = allyManager.getAllyById('non_existent');

      expect(foundAlly, null);
    });

    test('should update all allies and remove satisfied ones', () {
      allyManager.convertEnemyToAlly(enemy);
      final ally = allyManager.allies.first;

      // Make ally satisfied
      ally.satisfaction = 0;

      allyManager.updateAllies(tileMap, []);

      // Satisfied ally should be removed
      expect(allyManager.count, 0);
    });

    test('should get allies near a position', () {
      allyManager.convertEnemyToAlly(enemy);

      final nearbyAllies = allyManager.getAlliesNear(Position(6, 6), 2);

      expect(nearbyAllies, hasLength(1));
      expect(nearbyAllies.first.originalEnemy, enemy);
    });

    test('should get allies in combat', () {
      allyManager.convertEnemyToAlly(enemy);
      final ally = allyManager.allies.first;
      ally.state = AllyState.combat;

      final combatAllies = allyManager.getAlliesInCombat();

      expect(combatAllies, hasLength(1));
      expect(combatAllies.first, ally);
    });

    test('should get following allies', () {
      allyManager.convertEnemyToAlly(enemy);
      final ally = allyManager.allies.first;
      ally.state = AllyState.following;

      final followingAllies = allyManager.getFollowingAllies();

      expect(followingAllies, hasLength(1));
      expect(followingAllies.first, ally);
    });

    test('should apply global combat bonus to all allies', () {
      // Create multiple allies
      for (int i = 0; i < 3; i++) {
        final testEnemy = EnemyCharacter.human(
          id: 'enemy$i',
          position: Position(i, i),
          modelType: HumanModelType.maleA,
        );
        allyManager.convertEnemyToAlly(testEnemy);
      }

      allyManager.applyGlobalCombatBonus(5);

      for (final ally in allyManager.allies) {
        expect(ally.combatStrengthBonus, 5);
      }
    });

    test('should remove global combat bonus from all allies', () {
      allyManager.convertEnemyToAlly(enemy);
      final ally = allyManager.allies.first;
      ally.applyCombatStrengthBonus(10);

      allyManager.removeGlobalCombatBonus(5);

      expect(ally.combatStrengthBonus, 5);
    });

    test('should increase satisfaction for all allies', () {
      allyManager.convertEnemyToAlly(enemy);
      final ally = allyManager.allies.first;
      ally.satisfaction = 50;

      allyManager.increaseAllSatisfaction(20);

      expect(ally.satisfaction, 70);
    });

    test('should calculate total combat strength', () {
      // Create multiple allies
      for (int i = 0; i < 3; i++) {
        final testEnemy = EnemyCharacter.human(
          id: 'enemy$i',
          position: Position(i, i),
          modelType: HumanModelType.maleA,
        );
        allyManager.convertEnemyToAlly(testEnemy);
      }

      final totalStrength = allyManager.getTotalCombatStrength();

      expect(totalStrength, 30); // 3 allies * 10 base strength each
    });

    test('should group allies by type', () {
      // Create human ally
      allyManager.convertEnemyToAlly(enemy);

      // Create monster ally
      final monsterEnemy = EnemyCharacter.monster(
        id: 'monster1',
        position: Position(7, 7),
        modelType: MonsterModelType.skeleton,
      );
      allyManager.convertEnemyToAlly(monsterEnemy);

      final grouped = allyManager.getAlliesByType();

      expect(grouped[EnemyType.human], hasLength(1));
      expect(grouped[EnemyType.monster], hasLength(1));
    });

    test('should calculate average satisfaction', () {
      // Create allies with different satisfaction levels
      allyManager.convertEnemyToAlly(enemy);
      allyManager.allies.first.satisfaction = 80;

      final enemy2 = EnemyCharacter.human(
        id: 'enemy2',
        position: Position(7, 7),
        modelType: HumanModelType.femaleA,
      );
      allyManager.convertEnemyToAlly(enemy2);
      allyManager.allies.last.satisfaction = 60;

      final avgSatisfaction = allyManager.getAverageSatisfaction();

      expect(avgSatisfaction, 0.7); // (0.8 + 0.6) / 2
    });

    test('should identify low satisfaction allies', () {
      allyManager.convertEnemyToAlly(enemy);
      allyManager.allies.first.satisfaction = 20; // Low satisfaction

      expect(allyManager.hasLowSatisfactionAllies(), true);

      final lowSatAllies = allyManager.getLowSatisfactionAllies();
      expect(lowSatAllies, hasLength(1));
    });

    test('should activate and deactivate all allies', () {
      allyManager.convertEnemyToAlly(enemy);

      allyManager.deactivateAllAllies();
      expect(allyManager.allies.first.isActive, false);

      allyManager.activateAllAllies();
      expect(allyManager.allies.first.isActive, true);
    });

    test('should clear all allies', () {
      allyManager.convertEnemyToAlly(enemy);
      expect(allyManager.count, 1);

      allyManager.clearAllAllies();

      expect(allyManager.count, 0);
      expect(allyManager.allies, isEmpty);
    });

    test('should provide comprehensive ally summary', () {
      // Create allies with different states
      allyManager.convertEnemyToAlly(enemy);
      allyManager.allies.first.state = AllyState.following;

      final enemy2 = EnemyCharacter.monster(
        id: 'enemy2',
        position: Position(7, 7),
        modelType: MonsterModelType.skeleton,
      );
      allyManager.convertEnemyToAlly(enemy2);
      allyManager.allies.last.state = AllyState.combat;

      final summary = allyManager.getAllySummary();

      expect(summary['total'], 2);
      expect(summary['maxCapacity'], 5);
      expect(summary['following'], 1);
      expect(summary['inCombat'], 1);
      expect(summary['byType']['Human'], 1);
      expect(summary['byType']['Monster'], 1);
    });
  });
}
