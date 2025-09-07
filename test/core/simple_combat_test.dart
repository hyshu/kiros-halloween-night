import 'package:test/test.dart';
import 'package:kiro_halloween_game/core/character.dart';
import 'package:kiro_halloween_game/core/combat_manager.dart';
import 'package:kiro_halloween_game/core/health_system.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('Simple Combat Tests', () {
    test('CombatManager can be created', () {
      final healthSystem = HealthSystem();
      final combatManager = CombatManager(healthSystem: healthSystem);

      expect(combatManager, isNotNull);
      expect(combatManager.activeCombats, isEmpty);
    });

    test('HealthSystem can track damage', () {
      final healthSystem = HealthSystem();

      // Create a simple mock character for testing
      final character = MockCharacter('test', 50, 50);

      final survived = healthSystem.applyDamage(character, 20);

      expect(survived, isTrue);
      expect(character.health, equals(30));

      final tracker = healthSystem.getHealthTracker('test');
      expect(tracker, isNotNull);
      expect(tracker!.totalDamageTaken, equals(20));
    });

    test('HealthSystem can track healing', () {
      final healthSystem = HealthSystem();

      final character = MockCharacter('test', 30, 50);

      healthSystem.applyHealing(character, 15);

      expect(character.health, equals(45));

      final tracker = healthSystem.getHealthTracker('test');
      expect(tracker, isNotNull);
      expect(tracker!.totalHealingReceived, equals(15));
    });

    test('HealthSystem handles character defeat', () {
      final healthSystem = HealthSystem();

      final character = MockCharacter('test', 10, 50);

      final survived = healthSystem.applyDamage(character, 15);

      expect(survived, isFalse);
      expect(character.health, equals(0));

      final events = healthSystem.getEventsForCharacter('test');
      expect(
        events.any((e) => e.changeType == HealthChangeType.defeated),
        isTrue,
      );
    });
  });
}

/// Simple mock character for testing
class MockCharacter extends Character {
  MockCharacter(String id, int health, int maxHealth)
    : super(
        id: id,
        position: Position(0, 0),
        modelPath: 'test_model',
        health: health,
        maxHealth: maxHealth,
      );

  @override
  bool takeDamage(int damage) {
    health = (health - damage).clamp(0, maxHealth);
    return health > 0;
  }

  @override
  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
  }
}
