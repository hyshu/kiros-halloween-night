import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart';
import 'package:kiro_halloween_game/core/candy_item.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('CandyItem', () {
    test('should create candy bar with correct properties', () {
      final position = Position(5, 10);
      final candy = CandyItem.create(
        CandyType.candyBar,
        'candy_1',
        position: position,
      );

      expect(candy.id, equals('candy_1'));
      expect(candy.name, equals('Candy Bar'));
      expect(candy.modelPath, equals('assets/foods/candy-bar.obj'));
      expect(candy.effect, equals(CandyEffect.healthBoost));
      expect(candy.value, equals(20));
      expect(candy.position, equals(position));
      expect(candy.isCollected, isFalse);
      expect(candy.description, contains('restores 20 health'));
    });

    test('should create chocolate with max health increase effect', () {
      final candy = CandyItem.create(CandyType.chocolate, 'choc_1');

      expect(candy.name, equals('Chocolate'));
      expect(candy.effect, equals(CandyEffect.maxHealthIncrease));
      expect(candy.value, equals(10));
      expect(candy.modelPath, equals('assets/foods/chocolate.obj'));
    });

    test('should create cookie with speed increase and temporary effect', () {
      final candy = CandyItem.create(CandyType.cookie, 'cookie_1');

      expect(candy.name, equals('Cookie'));
      expect(candy.effect, equals(CandyEffect.speedIncrease));
      expect(candy.value, equals(2));
      expect(candy.isTemporaryEffect, isTrue);
      expect(candy.effectDuration, equals(30));
      expect(candy.abilityModifications['speedMultiplier'], equals(1.5));
    });

    test('should create ice cream with special ability', () {
      final candy = CandyItem.create(CandyType.iceCream, 'ice_1');

      expect(candy.name, equals('Ice Cream'));
      expect(candy.effect, equals(CandyEffect.specialAbility));
      expect(candy.abilityModifications['freezeEnemies'], isTrue);
      expect(candy.effectDuration, equals(10));
    });

    test('should return correct world position', () {
      final position = Position(3, 7);
      final candy = CandyItem.create(
        CandyType.donut,
        'donut_1',
        position: position,
      );

      final worldPos = candy.worldPosition;
      final expectedPos = position.toWorldCoordinates();

      expect(worldPos.x, equals(expectedPos.$1));
      expect(worldPos.y, equals(expectedPos.$2));
      expect(worldPos.z, equals(expectedPos.$3));
    });

    test('should return identity matrix when no position set', () {
      final candy = CandyItem.create(CandyType.lollipop, 'lolly_1');

      final worldPos = candy.worldPosition;
      expect(worldPos, equals(Vector3.zero()));
    });

    test('should mark candy as collected', () {
      final candy = CandyItem.create(CandyType.muffin, 'muffin_1');

      expect(candy.isCollected, isFalse);
      candy.collect();
      expect(candy.isCollected, isTrue);
    });

    test('should create copy with new id and position', () {
      final originalPosition = Position(1, 2);
      final newPosition = Position(5, 6);
      final original = CandyItem.create(
        CandyType.cupcake,
        'cup_1',
        position: originalPosition,
      );

      final copy = original.copyWith(id: 'cup_2', position: newPosition);

      expect(copy.id, equals('cup_2'));
      expect(copy.position, equals(newPosition));
      expect(copy.name, equals(original.name));
      expect(copy.effect, equals(original.effect));
      expect(copy.value, equals(original.value));

      // Original should be unchanged
      expect(original.id, equals('cup_1'));
      expect(original.position, equals(originalPosition));
    });

    test('should handle all candy types', () {
      for (final type in CandyType.values) {
        final candy = CandyItem.create(type, 'test_${type.name}');

        expect(candy.id, equals('test_${type.name}'));
        expect(candy.name, isNotEmpty);
        expect(candy.modelPath, startsWith('assets/foods/'));
        expect(candy.modelPath, endsWith('.obj'));
        expect(candy.description, isNotEmpty);
        expect(candy.value, greaterThan(0));
      }
    });

    test('should have correct model paths for candy types', () {
      final expectedPaths = {
        CandyType.candyBar: 'assets/foods/candy-bar.obj',
        CandyType.chocolate: 'assets/foods/chocolate.obj',
        CandyType.cookie: 'assets/foods/cookie.obj',
        CandyType.cupcake: 'assets/foods/cupcake.obj',
        CandyType.donut: 'assets/foods/donut.obj',
        CandyType.iceCream: 'assets/foods/ice-cream.obj',
        CandyType.lollipop: 'assets/foods/lollypop.obj',
        CandyType.popsicle: 'assets/foods/popsicle.obj',
        CandyType.gingerbread: 'assets/foods/ginger-bread.obj',
        CandyType.muffin: 'assets/foods/muffin.obj',
      };

      for (final entry in expectedPaths.entries) {
        final candy = CandyItem.create(entry.key, 'test');
        expect(candy.modelPath, equals(entry.value));
      }
    });

    test('should have appropriate effects for candy types', () {
      final healthBoostTypes = [
        CandyType.candyBar,
        CandyType.donut,
        CandyType.popsicle,
        CandyType.muffin,
      ];

      for (final type in healthBoostTypes) {
        final candy = CandyItem.create(type, 'test');
        expect(candy.effect, equals(CandyEffect.healthBoost));
      }

      expect(
        CandyItem.create(CandyType.chocolate, 'test').effect,
        equals(CandyEffect.maxHealthIncrease),
      );
      expect(
        CandyItem.create(CandyType.cookie, 'test').effect,
        equals(CandyEffect.speedIncrease),
      );
      expect(
        CandyItem.create(CandyType.cupcake, 'test').effect,
        equals(CandyEffect.allyStrength),
      );
    });
  });
}
