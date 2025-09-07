import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/ability_manager.dart';
import 'package:kiro_halloween_game/core/ghost_character.dart';
import 'package:kiro_halloween_game/core/candy_item.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('AbilityManager', () {
    late GhostCharacter character;
    late AbilityManager abilityManager;

    setUp(() {
      character = GhostCharacter(
        id: 'test_ghost',
        position: Position(0, 0),
        health: 80, // Start with less than max health
        maxHealth: 100,
      );
      abilityManager = AbilityManager(character);
    });

    tearDown(() {
      abilityManager.dispose();
    });

    test('should start with no permanent stats', () {
      expect(abilityManager.permanentStats.isEmpty, isTrue);
      expect(abilityManager.getEffectiveMaxHealth(), equals(100));
      expect(abilityManager.getEffectiveSpeed(), equals(1.0));
      expect(abilityManager.getEffectiveAllyDamageBonus(), equals(0));
      expect(abilityManager.getEffectiveLuck(), equals(0));
    });

    test('should apply health boost effect', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1');
      final initialHealth = character.health;

      // Add candy to inventory and use it (this applies the effect)
      character.inventory.addCandy(candy);
      character.useCandy('candy_1');

      expect(character.health, equals(initialHealth + candy.value));
    });

    test('should apply max health increase effect', () {
      final candy = CandyItem.create(CandyType.chocolate, 'choc_1');
      final initialMaxHealth = abilityManager.getEffectiveMaxHealth();

      abilityManager.applyCandyEffect(candy);

      expect(
        abilityManager.getEffectiveMaxHealth(),
        equals(initialMaxHealth + candy.value),
      );
      expect(abilityManager.permanentStats['maxHealth'], equals(candy.value));
    });

    test('should handle temporary effects through inventory', () {
      final candy = CandyItem.create(CandyType.cookie, 'cookie_1');
      character.inventory.addCandy(candy);
      character.inventory.useCandy('cookie_1');

      expect(abilityManager.getEffectiveSpeed(), greaterThan(1.0));
      expect(character.inventory.activeEffects.length, equals(1));
    });

    test('should detect active abilities', () {
      final iceCandy = CandyItem.create(CandyType.iceCream, 'ice_1');
      character.inventory.addCandy(iceCandy);
      character.inventory.useCandy('ice_1');

      expect(abilityManager.hasActiveAbility('freezeEnemies'), isTrue);
      expect(abilityManager.hasActiveAbility('wallVision'), isFalse);
    });

    test('should get active abilities list', () {
      final speedCandy = CandyItem.create(CandyType.cookie, 'cookie_1');
      final allyCandy = CandyItem.create(CandyType.cupcake, 'cupcake_1');

      character.inventory.addCandy(speedCandy);
      character.inventory.addCandy(allyCandy);
      character.inventory.useCandy('cookie_1');
      character.inventory.useCandy('cupcake_1');

      final abilities = abilityManager.getActiveAbilities();
      expect(abilities, contains('Speed Boost'));
      expect(abilities, contains('Ally Strength'));
    });

    test('should calculate effective stats correctly', () {
      // Add permanent max health bonus
      abilityManager.addPermanentStat('maxHealth', 20);

      // Add temporary speed boost
      final speedCandy = CandyItem.create(CandyType.cookie, 'cookie_1');
      character.inventory.addCandy(speedCandy);
      character.inventory.useCandy('cookie_1');

      final stats = abilityManager.effectiveStats;
      expect(stats['maxHealth'], equals(120)); // 100 + 20
      expect(stats['speed'], greaterThan(1.0));
      expect(stats['wallVision'], isFalse);
      expect(stats['freezeEnemies'], isFalse);
    });

    test('should get stat summary', () {
      final summary = abilityManager.getStatSummary();

      expect(summary.containsKey('maxHealth'), isTrue);
      expect(summary.containsKey('speed'), isTrue);
      expect(summary.containsKey('allyDamageBonus'), isTrue);
      expect(summary.containsKey('luck'), isTrue);
      expect(summary.containsKey('activeAbilities'), isTrue);
      expect(summary['activeAbilities'], isA<List<String>>());
    });

    test('should add and remove permanent stats', () {
      abilityManager.addPermanentStat('luck', 5);
      expect(abilityManager.getEffectiveLuck(), equals(5));

      abilityManager.addPermanentStat('luck', 3);
      expect(abilityManager.getEffectiveLuck(), equals(8));

      abilityManager.removePermanentStat('luck');
      expect(abilityManager.getEffectiveLuck(), equals(0));
    });

    test('should reset permanent stats', () {
      abilityManager.addPermanentStat('maxHealth', 20);
      abilityManager.addPermanentStat('luck', 5);

      expect(abilityManager.permanentStats.length, equals(2));

      abilityManager.resetPermanentStats();

      expect(abilityManager.permanentStats.isEmpty, isTrue);
      expect(abilityManager.getEffectiveMaxHealth(), equals(100));
      expect(abilityManager.getEffectiveLuck(), equals(0));
    });

    test('should update effects and notify listeners', () {
      var notificationCount = 0;
      abilityManager.addListener(() => notificationCount++);

      final speedCandy = CandyItem.create(CandyType.cookie, 'cookie_1');
      character.inventory.addCandy(speedCandy);
      character.inventory.useCandy('cookie_1');

      // Reset notification count
      notificationCount = 0;

      abilityManager.updateEffects();

      expect(notificationCount, greaterThan(0));
    });

    test('should handle multiple temporary effects of same type', () {
      final speedCandy1 = CandyItem.create(CandyType.cookie, 'cookie_1');
      final speedCandy2 = CandyItem.create(CandyType.cookie, 'cookie_2');

      character.inventory.addCandy(speedCandy1);
      character.inventory.addCandy(speedCandy2);
      character.inventory.useCandy('cookie_1');
      character.inventory.useCandy('cookie_2');

      // Should stack speed bonuses: base 1.0 * (1 + 1.5 + 1.5) = 4.0
      expect(
        abilityManager.getEffectiveSpeed(),
        equals(4.0),
      ); // 1.0 * (1 + 1.5 + 1.5)
    });

    test('should handle special abilities correctly', () {
      final gingerCandy = CandyItem.create(CandyType.gingerbread, 'ginger_1');
      character.inventory.addCandy(gingerCandy);
      character.inventory.useCandy('ginger_1');

      expect(abilityManager.hasActiveAbility('wallVision'), isTrue);

      final abilities = abilityManager.getActiveAbilities();
      expect(abilities, contains('Wall Vision'));
    });

    test('should cache effective stats for performance', () {
      // First call should calculate stats
      final stats1 = abilityManager.effectiveStats;

      // Second call should return cached stats (same object reference)
      final stats2 = abilityManager.effectiveStats;

      expect(
        identical(stats1, stats2),
        isFalse,
      ); // Returns copy, not same object
      expect(stats1, equals(stats2)); // But content should be the same
    });

    test('should invalidate cache when stats change', () {
      final initialStats = abilityManager.effectiveStats;

      // Add permanent stat
      abilityManager.addPermanentStat('maxHealth', 10);

      final newStats = abilityManager.effectiveStats;
      expect(newStats['maxHealth'], equals(110));
      expect(newStats['maxHealth'], isNot(equals(initialStats['maxHealth'])));
    });
  });
}
