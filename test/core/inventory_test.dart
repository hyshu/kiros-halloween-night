import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/inventory.dart';
import '../../lib/core/candy_item.dart';
import '../../lib/core/position.dart';

void main() {
  group('Inventory', () {
    late Inventory inventory;

    setUp(() {
      inventory = Inventory(maxCapacity: 10);
    });

    test('should start empty', () {
      expect(inventory.isEmpty, isTrue);
      expect(inventory.isFull, isFalse);
      expect(inventory.count, equals(0));
      expect(inventory.remainingCapacity, equals(10));
    });

    test('should add candy items', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1');
      
      final success = inventory.addCandy(candy);
      
      expect(success, isTrue);
      expect(inventory.count, equals(1));
      expect(inventory.isEmpty, isFalse);
      expect(candy.isCollected, isTrue);
    });

    test('should not add candy when full', () {
      // Fill inventory to capacity
      for (int i = 0; i < 10; i++) {
        final candy = CandyItem.create(CandyType.candyBar, 'candy_$i');
        inventory.addCandy(candy);
      }
      
      expect(inventory.isFull, isTrue);
      
      // Try to add one more
      final extraCandy = CandyItem.create(CandyType.chocolate, 'extra');
      final success = inventory.addCandy(extraCandy);
      
      expect(success, isFalse);
      expect(inventory.count, equals(10));
      expect(extraCandy.isCollected, isFalse);
    });

    test('should remove candy items', () {
      final candy1 = CandyItem.create(CandyType.candyBar, 'candy_1');
      final candy2 = CandyItem.create(CandyType.chocolate, 'candy_2');
      
      inventory.addCandy(candy1);
      inventory.addCandy(candy2);
      expect(inventory.count, equals(2));
      
      final removed = inventory.removeCandy(candy1);
      
      expect(removed, isTrue);
      expect(inventory.count, equals(1));
      expect(inventory.getCandyById('candy_1'), isNull);
      expect(inventory.getCandyById('candy_2'), isNotNull);
    });

    test('should remove candy by ID', () {
      final candy = CandyItem.create(CandyType.cookie, 'cookie_1');
      inventory.addCandy(candy);
      
      final removed = inventory.removeCandyById('cookie_1');
      
      expect(removed, equals(candy));
      expect(inventory.count, equals(0));
      
      // Try to remove non-existent candy
      final notFound = inventory.removeCandyById('not_found');
      expect(notFound, isNull);
    });

    test('should get candy by ID', () {
      final candy = CandyItem.create(CandyType.donut, 'donut_1');
      inventory.addCandy(candy);
      
      final found = inventory.getCandyById('donut_1');
      expect(found, equals(candy));
      
      final notFound = inventory.getCandyById('not_found');
      expect(notFound, isNull);
    });

    test('should get candy by type', () {
      final candy1 = CandyItem.create(CandyType.candyBar, 'candy_1');
      final candy2 = CandyItem.create(CandyType.candyBar, 'candy_2');
      final candy3 = CandyItem.create(CandyType.chocolate, 'choc_1');
      
      inventory.addCandy(candy1);
      inventory.addCandy(candy2);
      inventory.addCandy(candy3);
      
      final candyBars = inventory.getCandyByType(CandyType.candyBar);
      expect(candyBars.length, equals(2));
      expect(candyBars, contains(candy1));
      expect(candyBars, contains(candy2));
      
      final chocolates = inventory.getCandyByType(CandyType.chocolate);
      expect(chocolates.length, equals(1));
      expect(chocolates, contains(candy3));
    });

    test('should get candy by effect', () {
      final healthCandy1 = CandyItem.create(CandyType.candyBar, 'candy_1');
      final healthCandy2 = CandyItem.create(CandyType.donut, 'donut_1');
      final speedCandy = CandyItem.create(CandyType.cookie, 'cookie_1');
      
      inventory.addCandy(healthCandy1);
      inventory.addCandy(healthCandy2);
      inventory.addCandy(speedCandy);
      
      final healthCandies = inventory.getCandyByEffect(CandyEffect.healthBoost);
      expect(healthCandies.length, equals(2));
      
      final speedCandies = inventory.getCandyByEffect(CandyEffect.speedIncrease);
      expect(speedCandies.length, equals(1));
    });

    test('should use candy and apply effects', () {
      final candy = CandyItem.create(CandyType.cookie, 'cookie_1');
      inventory.addCandy(candy);
      
      expect(inventory.count, equals(1));
      
      final success = inventory.useCandy('cookie_1');
      
      expect(success, isTrue);
      expect(inventory.count, equals(0)); // Candy should be removed
      expect(inventory.activeEffects.length, equals(1)); // Temporary effect added
    });

    test('should track temporary effects', () {
      final speedCandy = CandyItem.create(CandyType.cookie, 'cookie_1');
      inventory.addCandy(speedCandy);
      inventory.useCandy('cookie_1');
      
      expect(inventory.activeEffects.length, equals(1));
      
      final effect = inventory.activeEffects.values.first;
      expect(effect.effect, equals(CandyEffect.speedIncrease));
      expect(effect.remainingDuration, equals(30));
      expect(effect.sourceId, equals('cookie_1'));
    });

    test('should update temporary effects', () {
      final speedCandy = CandyItem.create(CandyType.cookie, 'cookie_1');
      inventory.addCandy(speedCandy);
      inventory.useCandy('cookie_1');
      
      final initialDuration = inventory.activeEffects.values.first.remainingDuration;
      
      inventory.updateTemporaryEffects();
      
      final updatedDuration = inventory.activeEffects.values.first.remainingDuration;
      expect(updatedDuration, equals(initialDuration - 1));
    });

    test('should remove expired effects', () {
      final speedCandy = CandyItem.create(CandyType.cookie, 'cookie_1');
      inventory.addCandy(speedCandy);
      inventory.useCandy('cookie_1');
      
      // Manually set duration to 1
      inventory.activeEffects.values.first.remainingDuration = 1;
      
      inventory.updateTemporaryEffects();
      expect(inventory.activeEffects.isEmpty, isTrue);
    });

    test('should calculate total ability modifications', () {
      final speedCandy1 = CandyItem.create(CandyType.cookie, 'cookie_1');
      final speedCandy2 = CandyItem.create(CandyType.cookie, 'cookie_2');
      
      inventory.addCandy(speedCandy1);
      inventory.addCandy(speedCandy2);
      inventory.useCandy('cookie_1');
      inventory.useCandy('cookie_2');
      
      final totalSpeedBonus = inventory.getTotalAbilityModification('speedMultiplier');
      expect(totalSpeedBonus, equals(3.0)); // 1.5 + 1.5
    });

    test('should check for active abilities', () {
      final iceCandy = CandyItem.create(CandyType.iceCream, 'ice_1');
      inventory.addCandy(iceCandy);
      inventory.useCandy('ice_1');
      
      expect(inventory.hasActiveAbility('freezeEnemies'), isTrue);
      expect(inventory.hasActiveAbility('wallVision'), isFalse);
    });

    test('should get available candy for gifting', () {
      final healthCandy = CandyItem.create(CandyType.candyBar, 'candy_1');
      final speedCandy = CandyItem.create(CandyType.cookie, 'cookie_1');
      
      inventory.addCandy(healthCandy);
      inventory.addCandy(speedCandy);
      
      // Before using any candy
      final available1 = inventory.getAvailableForGifting();
      expect(available1.length, equals(2));
      
      // After using speed candy (creates temporary effect)
      inventory.useCandy('cookie_1');
      final available2 = inventory.getAvailableForGifting();
      expect(available2.length, equals(1)); // Only health candy available
      expect(available2.first, equals(healthCandy));
    });

    test('should get inventory summary', () {
      final candy1 = CandyItem.create(CandyType.candyBar, 'candy_1');
      final candy2 = CandyItem.create(CandyType.candyBar, 'candy_2');
      final candy3 = CandyItem.create(CandyType.chocolate, 'choc_1');
      
      inventory.addCandy(candy1);
      inventory.addCandy(candy2);
      inventory.addCandy(candy3);
      
      final summary = inventory.getInventorySummary();
      expect(summary['Candy Bar'], equals(2));
      expect(summary['Chocolate'], equals(1));
    });

    test('should sort candy by name', () {
      final zCandy = CandyItem.create(CandyType.popsicle, 'z'); // Popsicle
      final aCandy = CandyItem.create(CandyType.candyBar, 'a'); // Candy Bar
      final mCandy = CandyItem.create(CandyType.muffin, 'm'); // Muffin
      
      inventory.addCandy(zCandy);
      inventory.addCandy(aCandy);
      inventory.addCandy(mCandy);
      
      final sorted = inventory.getCandySortedByName();
      expect(sorted[0].name, equals('Candy Bar'));
      expect(sorted[1].name, equals('Muffin'));
      expect(sorted[2].name, equals('Popsicle'));
    });

    test('should clear inventory', () {
      final candy1 = CandyItem.create(CandyType.candyBar, 'candy_1');
      final candy2 = CandyItem.create(CandyType.cookie, 'cookie_1');
      
      inventory.addCandy(candy1);
      inventory.addCandy(candy2);
      inventory.useCandy('cookie_1'); // Creates temporary effect
      
      expect(inventory.count, equals(1));
      expect(inventory.activeEffects.length, equals(1));
      
      inventory.clear();
      
      expect(inventory.isEmpty, isTrue);
      expect(inventory.activeEffects.isEmpty, isTrue);
    });
  });

  group('TemporaryEffect', () {
    test('should create temporary effect correctly', () {
      final effect = TemporaryEffect(
        id: 'speed_1',
        sourceId: 'cookie_1',
        name: 'Speed Boost',
        effect: CandyEffect.speedIncrease,
        value: 2,
        abilityModifications: {'speedMultiplier': 1.5},
        remainingDuration: 30,
      );
      
      expect(effect.id, equals('speed_1'));
      expect(effect.sourceId, equals('cookie_1'));
      expect(effect.name, equals('Speed Boost'));
      expect(effect.isExpired, isFalse);
      expect(effect.remainingDuration, equals(30));
    });

    test('should detect expired effects', () {
      final effect = TemporaryEffect(
        id: 'test',
        sourceId: 'test',
        name: 'Test',
        effect: CandyEffect.speedIncrease,
        value: 1,
        abilityModifications: {},
        remainingDuration: 0,
      );
      
      expect(effect.isExpired, isTrue);
    });
  });
}