import 'package:test/test.dart';
import 'package:kiro_halloween_game/core/ally_lifecycle_manager.dart';
import 'package:kiro_halloween_game/core/ally_character.dart';
import 'package:kiro_halloween_game/core/enemy_character.dart';
import 'package:kiro_halloween_game/core/health_system.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('AllyLifecycleManager', () {
    late AllyLifecycleManager lifecycleManager;
    late HealthSystem healthSystem;

    setUp(() {
      healthSystem = HealthSystem();
      lifecycleManager = AllyLifecycleManager(healthSystem: healthSystem);
    });

    group('Ally Management', () {
      test('should add and track allies correctly', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy);

        expect(lifecycleManager.allyCount, equals(0));

        lifecycleManager.addAlly(ally);

        expect(lifecycleManager.allyCount, equals(1));
        expect(lifecycleManager.activeAllies, contains(ally));
      });

      test('should not add duplicate allies', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy);

        lifecycleManager.addAlly(ally);
        lifecycleManager.addAlly(ally); // Try to add again

        expect(lifecycleManager.allyCount, equals(1));
      });

      test('should remove allies correctly', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy);

        lifecycleManager.addAlly(ally);
        expect(lifecycleManager.allyCount, equals(1));

        lifecycleManager.removeAlly(ally);
        expect(lifecycleManager.allyCount, equals(0));
        expect(lifecycleManager.activeAllies, isEmpty);
      });

      test('should call callbacks when allies are added', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy);

        AllyCharacter? addedAlly;
        lifecycleManager.onAllyAdded((ally) {
          addedAlly = ally;
        });

        lifecycleManager.addAlly(ally);

        expect(addedAlly, equals(ally));
      });

      test('should call callbacks when allies are removed', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy);

        AllyCharacter? removedAlly;
        lifecycleManager.onAllyRemoved((ally) {
          removedAlly = ally;
        });

        lifecycleManager.addAlly(ally);
        lifecycleManager.removeAlly(ally);

        expect(removedAlly, equals(ally));
      });
    });

    group('Satisfaction Management', () {
      test('should remove satisfied allies during update', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(
          originalEnemy: enemy,
          satisfaction: 0, // Already satisfied
        );
        ally.state = AllyState.satisfied;

        lifecycleManager.addAlly(ally);
        expect(lifecycleManager.allyCount, equals(1));

        lifecycleManager.updateAllies();

        expect(lifecycleManager.allyCount, equals(0));
        expect(lifecycleManager.satisfiedAllies, contains(ally));
      });

      test('should call satisfaction callback when ally becomes satisfied', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy, satisfaction: 0);
        ally.state = AllyState.satisfied;

        AllyCharacter? satisfiedAlly;
        lifecycleManager.onAllySatisfied((ally) {
          satisfiedAlly = ally;
        });

        lifecycleManager.addAlly(ally);
        lifecycleManager.updateAllies();

        expect(satisfiedAlly, equals(ally));
      });

      test('should increase satisfaction for all allies', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(6, 6),
          modelPath: 'test.obj',
        );

        final ally1 = AllyCharacter(originalEnemy: enemy1, satisfaction: 50);

        final ally2 = AllyCharacter(originalEnemy: enemy2, satisfaction: 60);

        lifecycleManager.addAlly(ally1);
        lifecycleManager.addAlly(ally2);

        lifecycleManager.increaseSatisfactionForAll(20);

        expect(ally1.satisfaction, equals(70));
        expect(ally2.satisfaction, equals(80));
      });

      test('should increase satisfaction for specific ally', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy, satisfaction: 50);

        lifecycleManager.addAlly(ally);
        lifecycleManager.increaseSatisfactionFor(ally, 30);

        expect(ally.satisfaction, equals(80));
      });

      test('should force ally satisfaction', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy, satisfaction: 80);

        lifecycleManager.addAlly(ally);
        lifecycleManager.forceSatisfaction(ally);

        expect(ally.satisfaction, equals(0));
        expect(ally.state, equals(AllyState.satisfied));
      });

      test('should restore ally satisfaction', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy, satisfaction: 20);
        ally.state = AllyState.satisfied;

        lifecycleManager.addAlly(ally);
        lifecycleManager.restoreSatisfaction(ally);

        expect(ally.satisfaction, equals(ally.maxSatisfaction));
        expect(ally.state, equals(AllyState.following));
      });
    });

    group('Ally Filtering and Queries', () {
      test('should identify allies with low satisfaction', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(6, 6),
          modelPath: 'test.obj',
        );

        final ally1 = AllyCharacter(
          originalEnemy: enemy1,
          satisfaction: 20, // Low satisfaction (20%)
        );

        final ally2 = AllyCharacter(
          originalEnemy: enemy2,
          satisfaction: 80, // High satisfaction (80%)
        );

        lifecycleManager.addAlly(ally1);
        lifecycleManager.addAlly(ally2);

        final lowSatisfactionAllies =
            lifecycleManager.alliesWithLowSatisfaction;

        expect(lowSatisfactionAllies, hasLength(1));
        expect(lowSatisfactionAllies, contains(ally1));
        expect(lowSatisfactionAllies, isNot(contains(ally2)));
      });

      test('should identify allies with critical health', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(6, 6),
          modelPath: 'test.obj',
        );

        final ally1 = AllyCharacter(originalEnemy: enemy1);
        ally1.health = 5; // Critical health (10% of 50)

        final ally2 = AllyCharacter(originalEnemy: enemy2);
        ally2.health = 40; // Good health (80% of 50)

        lifecycleManager.addAlly(ally1);
        lifecycleManager.addAlly(ally2);

        final criticalHealthAllies = lifecycleManager.alliesWithCriticalHealth;

        expect(criticalHealthAllies, hasLength(1));
        expect(criticalHealthAllies, contains(ally1));
        expect(criticalHealthAllies, isNot(contains(ally2)));
      });

      test('should identify allies in combat', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(6, 6),
          modelPath: 'test.obj',
        );

        final ally1 = AllyCharacter(originalEnemy: enemy1);
        ally1.state = AllyState.combat;

        final ally2 = AllyCharacter(originalEnemy: enemy2);
        ally2.state = AllyState.following;

        lifecycleManager.addAlly(ally1);
        lifecycleManager.addAlly(ally2);

        final combatAllies = lifecycleManager.alliesInCombat;

        expect(combatAllies, hasLength(1));
        expect(combatAllies, contains(ally1));
        expect(combatAllies, isNot(contains(ally2)));
      });
    });

    group('Statistics and Information', () {
      test('should provide accurate lifecycle statistics', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(6, 6),
          modelPath: 'test.obj',
        );

        final ally1 = AllyCharacter(originalEnemy: enemy1, satisfaction: 80);
        ally1.health = 40;

        final ally2 = AllyCharacter(originalEnemy: enemy2, satisfaction: 60);
        ally2.health = 30;

        lifecycleManager.addAlly(ally1);
        lifecycleManager.addAlly(ally2);

        final stats = lifecycleManager.stats;

        expect(stats.activeAllies, equals(2));
        expect(stats.satisfiedAllies, equals(0));
        expect(stats.averageSatisfaction, equals(0.7)); // (0.8 + 0.6) / 2
        expect(stats.averageHealth, equals(0.7)); // (0.8 + 0.6) / 2
      });

      test('should provide ally information', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy);

        lifecycleManager.addAlly(ally);

        final info = lifecycleManager.getAllyInfo(ally);

        expect(info, isNotNull);
        expect(info!.ally, equals(ally));
        expect(info.statusSummary, contains(ally.id));
      });

      test('should return null for ally info of non-managed ally', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy);

        // Don't add ally to manager

        final info = lifecycleManager.getAllyInfo(ally);

        expect(info, isNull);
      });
    });

    group('Cleanup and Management', () {
      test('should clear all allies', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(6, 6),
          modelPath: 'test.obj',
        );

        final ally1 = AllyCharacter(originalEnemy: enemy1);
        final ally2 = AllyCharacter(originalEnemy: enemy2);

        lifecycleManager.addAlly(ally1);
        lifecycleManager.addAlly(ally2);

        expect(lifecycleManager.allyCount, equals(2));

        lifecycleManager.clear();

        expect(lifecycleManager.allyCount, equals(0));
        expect(lifecycleManager.satisfiedAllies, isEmpty);
      });

      test('should clear all callbacks', () {
        bool callbackCalled = false;
        lifecycleManager.onAllyAdded((ally) {
          callbackCalled = true;
        });

        lifecycleManager.clearCallbacks();

        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
        );

        final ally = AllyCharacter(originalEnemy: enemy);
        lifecycleManager.addAlly(ally);

        expect(callbackCalled, isFalse);
      });
    });
  });

  group('AllyLifecycleStats', () {
    test('should calculate retention rate correctly', () {
      final stats = AllyLifecycleStats(
        activeAllies: 3,
        satisfiedAllies: 2,
        alliesInCombat: 1,
        alliesWithLowSatisfaction: 1,
        alliesWithCriticalHealth: 0,
        averageSatisfaction: 0.7,
        averageHealth: 0.8,
      );

      expect(stats.totalAlliesEver, equals(5));
      expect(stats.satisfactionRetentionRate, equals(0.6)); // 3/5
    });

    test('should handle zero allies correctly', () {
      final stats = AllyLifecycleStats(
        activeAllies: 0,
        satisfiedAllies: 0,
        alliesInCombat: 0,
        alliesWithLowSatisfaction: 0,
        alliesWithCriticalHealth: 0,
        averageSatisfaction: 0.0,
        averageHealth: 0.0,
      );

      expect(stats.totalAlliesEver, equals(0));
      expect(
        stats.satisfactionRetentionRate,
        equals(1.0),
      ); // Perfect retention when no allies
    });
  });

  group('AllyInfo', () {
    test('should generate appropriate status summary', () {
      final enemy = EnemyCharacter(
        id: 'enemy1',
        position: Position(5, 5),
        modelPath: 'test.obj',
      );

      final ally = AllyCharacter(originalEnemy: enemy, satisfaction: 75);
      ally.health = 40; // 80% health

      final info = AllyInfo(
        ally: ally,
        healthStats: null,
        timeAsAlly: Duration(minutes: 5),
        combatParticipation: 3,
      );

      final summary = info.statusSummary;

      expect(summary, contains(ally.id));
      expect(summary, contains('80%')); // Health percentage
      expect(summary, contains('75%')); // Satisfaction percentage
      expect(summary, contains(ally.state.displayName));
    });
  });
}
