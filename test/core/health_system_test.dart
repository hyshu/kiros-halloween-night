import 'package:test/test.dart';
import '../../lib/core/health_system.dart';
import '../../lib/core/ally_character.dart';
import '../../lib/core/enemy_character.dart';
import '../../lib/core/position.dart';

void main() {
  group('HealthSystem', () {
    late HealthSystem healthSystem;

    setUp(() {
      healthSystem = HealthSystem();
    });

    group('Damage Application', () {
      test('should apply damage correctly and track health changes', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 50,
          maxHealth: 50,
        );

        final initialHealth = enemy.health;
        final survived = healthSystem.applyDamage(enemy, 20);

        expect(survived, isTrue);
        expect(enemy.health, equals(30));
        expect(enemy.health, lessThan(initialHealth));

        // Check health tracker was created
        final tracker = healthSystem.getHealthTracker(enemy.id);
        expect(tracker, isNotNull);
        expect(tracker!.totalDamageTaken, equals(20));
        expect(tracker.damageEvents, equals(1));
      });

      test('should handle character defeat when health reaches zero', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 10,
          maxHealth: 50,
        );

        final survived = healthSystem.applyDamage(enemy, 15);

        expect(survived, isFalse);
        expect(enemy.health, equals(0));
        expect(enemy.isSatisfied, isTrue);

        // Check defeat event was recorded
        final events = healthSystem.getEventsForCharacter(enemy.id);
        expect(events.any((e) => e.changeType == HealthChangeType.defeated), isTrue);
      });

      test('should not apply negative damage', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 50,
          maxHealth: 50,
        );

        final initialHealth = enemy.health;
        final survived = healthSystem.applyDamage(enemy, -10);

        expect(survived, isTrue);
        expect(enemy.health, equals(initialHealth));

        final tracker = healthSystem.getHealthTracker(enemy.id);
        expect(tracker, isNull); // No tracker should be created for invalid damage
      });

      test('should handle ally satisfaction when defeated', () {
        final originalEnemy = EnemyCharacter(
          id: 'original',
          position: Position(0, 0),
          modelPath: 'test.obj',
        );
        
        final ally = AllyCharacter(
          originalEnemy: originalEnemy,
        );
        ally.health = 10;

        final survived = healthSystem.applyDamage(ally, 15);

        expect(survived, isFalse);
        expect(ally.health, equals(0));
        expect(ally.isSatisfied, isTrue);
      });
    });

    group('Healing Application', () {
      test('should apply healing correctly and track health changes', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 30,
          maxHealth: 50,
        );

        healthSystem.applyHealing(enemy, 15);

        expect(enemy.health, equals(45));

        // Check health tracker
        final tracker = healthSystem.getHealthTracker(enemy.id);
        expect(tracker, isNotNull);
        expect(tracker!.totalHealingReceived, equals(15));
        expect(tracker.healingEvents, equals(1));
      });

      test('should not heal beyond maximum health', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 45,
          maxHealth: 50,
        );

        healthSystem.applyHealing(enemy, 20);

        expect(enemy.health, equals(50)); // Capped at max health

        final tracker = healthSystem.getHealthTracker(enemy.id);
        expect(tracker!.totalHealingReceived, equals(5)); // Only actual healing recorded
      });

      test('should not apply negative healing', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 30,
          maxHealth: 50,
        );

        final initialHealth = enemy.health;
        healthSystem.applyHealing(enemy, -10);

        expect(enemy.health, equals(initialHealth));

        final tracker = healthSystem.getHealthTracker(enemy.id);
        expect(tracker, isNull); // No tracker should be created for invalid healing
      });
    });

    group('Health Tracking', () {
      test('should track multiple health changes for a character', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 50,
          maxHealth: 50,
        );

        healthSystem.applyDamage(enemy, 20);
        healthSystem.applyHealing(enemy, 10);
        healthSystem.applyDamage(enemy, 5);

        final tracker = healthSystem.getHealthTracker(enemy.id);
        expect(tracker, isNotNull);
        expect(tracker!.totalDamageTaken, equals(25));
        expect(tracker.totalHealingReceived, equals(10));
        expect(tracker.damageEvents, equals(2));
        expect(tracker.healingEvents, equals(1));
        expect(tracker.currentHealth, equals(35));
      });

      test('should provide accurate health statistics', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 50,
          maxHealth: 50,
        );

        healthSystem.applyDamage(enemy, 20);
        healthSystem.applyHealing(enemy, 10);

        final stats = healthSystem.getHealthStats(enemy.id);
        expect(stats, isNotNull);
        expect(stats!.currentHealth, equals(40));
        expect(stats.maxHealth, equals(50));
        expect(stats.totalDamageTaken, equals(20));
        expect(stats.totalHealingReceived, equals(10));
        expect(stats.isAlive, isTrue);
        expect(stats.healthPercentage, equals(0.8));
        expect(stats.netHealthChange, equals(-10));
      });

      test('should track events for multiple characters', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 50,
          maxHealth: 50,
        );

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(6, 6),
          modelPath: 'test.obj',
          health: 40,
          maxHealth: 40,
        );

        healthSystem.applyDamage(enemy1, 15);
        healthSystem.applyDamage(enemy2, 10);

        expect(healthSystem.allHealthTrackers, hasLength(2));
        expect(healthSystem.recentEvents, hasLength(2));

        final enemy1Events = healthSystem.getEventsForCharacter('enemy1');
        final enemy2Events = healthSystem.getEventsForCharacter('enemy2');

        expect(enemy1Events, hasLength(1));
        expect(enemy2Events, hasLength(1));
      });
    });

    group('Event Management', () {
      test('should limit the number of recent events', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 1000,
          maxHealth: 1000,
        );

        // Apply damage many times to exceed the event limit
        for (int i = 0; i < 60; i++) {
          healthSystem.applyDamage(enemy, 1);
        }

        expect(healthSystem.recentEvents.length, lessThanOrEqualTo(50));
      });

      test('should identify critical health events', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 15,
          maxHealth: 50,
        );

        healthSystem.applyDamage(enemy, 10); // Brings health to 5 (critical)

        final events = healthSystem.getEventsForCharacter(enemy.id);
        expect(events.any((e) => e.isCritical), isTrue);
      });

      test('should create appropriate event descriptions', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 50,
          maxHealth: 50,
        );

        healthSystem.applyDamage(enemy, 20);
        healthSystem.applyHealing(enemy, 10);

        final events = healthSystem.getEventsForCharacter(enemy.id);
        expect(events, hasLength(2));

        final damageEvent = events.firstWhere((e) => e.changeType == HealthChangeType.damage);
        final healingEvent = events.firstWhere((e) => e.changeType == HealthChangeType.healing);

        expect(damageEvent.description, contains('took'));
        expect(damageEvent.description, contains('damage'));
        expect(healingEvent.description, contains('healed'));
      });
    });

    group('Cleanup and Management', () {
      test('should remove character tracking correctly', () {
        final enemy = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 50,
          maxHealth: 50,
        );

        healthSystem.applyDamage(enemy, 20);
        expect(healthSystem.getHealthTracker(enemy.id), isNotNull);

        healthSystem.removeCharacter(enemy.id);
        expect(healthSystem.getHealthTracker(enemy.id), isNull);

        final events = healthSystem.getEventsForCharacter(enemy.id);
        expect(events, isEmpty);
      });

      test('should clear all tracking data', () {
        final enemy1 = EnemyCharacter(
          id: 'enemy1',
          position: Position(5, 5),
          modelPath: 'test.obj',
          health: 50,
          maxHealth: 50,
        );

        final enemy2 = EnemyCharacter(
          id: 'enemy2',
          position: Position(6, 6),
          modelPath: 'test.obj',
          health: 40,
          maxHealth: 40,
        );

        healthSystem.applyDamage(enemy1, 15);
        healthSystem.applyDamage(enemy2, 10);

        expect(healthSystem.allHealthTrackers, isNotEmpty);
        expect(healthSystem.recentEvents, isNotEmpty);

        healthSystem.clearAll();

        expect(healthSystem.allHealthTrackers, isEmpty);
        expect(healthSystem.recentEvents, isEmpty);
      });
    });
  });

  group('HealthTracker', () {
    test('should calculate health percentage correctly', () {
      final tracker = HealthTracker(
        characterId: 'test',
        maxHealth: 100,
        currentHealth: 75,
      );

      expect(tracker.healthPercentage, equals(0.75));
      expect(tracker.isAlive, isTrue);
      expect(tracker.isFullHealth, isFalse);
    });

    test('should track damage and healing correctly', () {
      final tracker = HealthTracker(
        characterId: 'test',
        maxHealth: 100,
        currentHealth: 100,
      );

      tracker.recordDamage(30);
      expect(tracker.currentHealth, equals(70));
      expect(tracker.totalDamageTaken, equals(30));
      expect(tracker.damageEvents, equals(1));

      tracker.recordHealing(20);
      expect(tracker.currentHealth, equals(90));
      expect(tracker.totalHealingReceived, equals(20));
      expect(tracker.healingEvents, equals(1));

      expect(tracker.netHealthChange, equals(-10));
    });

    test('should handle health bounds correctly', () {
      final tracker = HealthTracker(
        characterId: 'test',
        maxHealth: 50,
        currentHealth: 30,
      );

      // Test damage beyond current health
      tracker.recordDamage(40);
      expect(tracker.currentHealth, equals(0));
      expect(tracker.isAlive, isFalse);

      // Test healing beyond max health
      tracker.currentHealth = 45;
      tracker.recordHealing(20);
      expect(tracker.currentHealth, equals(50));
      expect(tracker.isFullHealth, isTrue);
    });
  });

  group('HealthChangeEvent', () {
    test('should identify critical events correctly', () {
      final criticalDamage = HealthChangeEvent(
        characterId: 'test',
        changeType: HealthChangeType.damage,
        amount: 20,
        previousHealth: 15,
        newHealth: 5, // Critical health
        timestamp: DateTime.now(),
      );

      final normalDamage = HealthChangeEvent(
        characterId: 'test',
        changeType: HealthChangeType.damage,
        amount: 10,
        previousHealth: 50,
        newHealth: 40,
        timestamp: DateTime.now(),
      );

      final defeat = HealthChangeEvent(
        characterId: 'test',
        changeType: HealthChangeType.defeated,
        amount: 0,
        previousHealth: 0,
        newHealth: 0,
        timestamp: DateTime.now(),
      );

      expect(criticalDamage.isCritical, isTrue);
      expect(normalDamage.isCritical, isFalse);
      expect(defeat.isCritical, isTrue);
    });
  });
}