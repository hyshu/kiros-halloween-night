import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/gift_system.dart';
import '../../lib/core/ghost_character.dart';
import '../../lib/core/enemy_character.dart';
import '../../lib/core/candy_item.dart';
import '../../lib/core/position.dart';
import '../../lib/core/inventory.dart';

void main() {
  group('GiftSystem', () {
    late GiftSystem giftSystem;
    late GhostCharacter player;
    late EnemyCharacter enemy;
    late CandyItem candy;

    setUp(() {
      giftSystem = GiftSystem();
      player = GhostCharacter(
        id: 'player',
        position: Position(5, 5),
        inventory: Inventory(),
      );
      enemy = EnemyCharacter.human(
        id: 'enemy1',
        position: Position(5, 6), // Adjacent to player
        modelType: HumanModelType.maleA,
        state: EnemyState.hostile,
      );
      enemy.isProximityActive = true; // Make enemy active for gifting
      candy = CandyItem.create(CandyType.candyBar, 'candy1');
      player.inventory.addCandy(candy);
    });

    test('should initialize with correct default state', () {
      expect(giftSystem.isGiftUIActive, false);
      expect(giftSystem.selectedCandy, null);
      expect(giftSystem.targetEnemy, null);
      expect(giftSystem.availableCandy, isEmpty);
    });

    test('should successfully initiate gift with adjacent hostile enemy', () {
      final success = giftSystem.initiateGift(player, enemy);
      
      expect(success, true);
      expect(giftSystem.isGiftUIActive, true);
      expect(giftSystem.targetEnemy, enemy);
      expect(giftSystem.availableCandy, isNotEmpty);
      expect(giftSystem.availableCandy.first.id, candy.id);
    });

    test('should fail to initiate gift with non-adjacent enemy', () {
      enemy.position = Position(10, 10); // Far away
      
      final success = giftSystem.initiateGift(player, enemy);
      
      expect(success, false);
      expect(giftSystem.isGiftUIActive, false);
    });

    test('should fail to initiate gift with non-hostile enemy', () {
      enemy.state = EnemyState.ally;
      
      final success = giftSystem.initiateGift(player, enemy);
      
      expect(success, false);
      expect(giftSystem.isGiftUIActive, false);
    });

    test('should fail to initiate gift when player has no candy', () {
      player.inventory.clear();
      
      final success = giftSystem.initiateGift(player, enemy);
      
      expect(success, false);
      expect(giftSystem.isGiftUIActive, false);
    });

    test('should select candy for gifting', () {
      giftSystem.initiateGift(player, enemy);
      
      giftSystem.selectCandy(candy);
      
      expect(giftSystem.selectedCandy, candy);
    });

    test('should not select candy not in available list', () {
      final otherCandy = CandyItem.create(CandyType.chocolate, 'candy2');
      giftSystem.initiateGift(player, enemy);
      
      giftSystem.selectCandy(otherCandy);
      
      expect(giftSystem.selectedCandy, null);
    });

    test('should successfully confirm gift and convert enemy', () {
      giftSystem.initiateGift(player, enemy);
      giftSystem.selectCandy(candy);
      
      final success = giftSystem.confirmGift(player);
      
      expect(success, true);
      expect(giftSystem.isGiftUIActive, false);
      expect(enemy.state, EnemyState.ally);
      expect(player.inventory.getCandyById(candy.id), null); // Candy removed
    });

    test('should fail to confirm gift without selection', () {
      giftSystem.initiateGift(player, enemy);
      // Don't select candy
      
      final success = giftSystem.confirmGift(player);
      
      expect(success, false);
      expect(giftSystem.isGiftUIActive, true); // Still active
    });

    test('should cancel gift and reset state', () {
      giftSystem.initiateGift(player, enemy);
      giftSystem.selectCandy(candy);
      
      giftSystem.cancelGift();
      
      expect(giftSystem.isGiftUIActive, false);
      expect(giftSystem.selectedCandy, null);
      expect(giftSystem.targetEnemy, null);
      expect(giftSystem.availableCandy, isEmpty);
    });

    test('should identify adjacent positions correctly', () {
      final adjacentEnemies = giftSystem.getAdjacentGiftableEnemies(
        player, 
        [enemy]
      );
      
      expect(adjacentEnemies, contains(enemy));
    });

    test('should not identify non-adjacent positions as adjacent', () {
      enemy.position = Position(7, 7); // Diagonal, not adjacent
      
      final adjacentEnemies = giftSystem.getAdjacentGiftableEnemies(
        player, 
        [enemy]
      );
      
      expect(adjacentEnemies, isEmpty);
    });

    test('should check if player can give gifts', () {
      expect(giftSystem.canGiveGifts(player, [enemy]), true);
      
      // No candy
      player.inventory.clear();
      expect(giftSystem.canGiveGifts(player, [enemy]), false);
      
      // No adjacent enemies
      player.inventory.addCandy(candy);
      enemy.position = Position(10, 10);
      expect(giftSystem.canGiveGifts(player, [enemy]), false);
    });

    test('should recommend appropriate candy for human enemies', () {
      final chocolateCandy = CandyItem.create(CandyType.chocolate, 'choc1');
      player.inventory.clear(); // Clear existing candy
      player.inventory.addCandy(chocolateCandy);
      
      final recommended = giftSystem.getRecommendedCandy(
        enemy, 
        player.inventory.candyItems
      );
      
      expect(recommended, isNotNull);
      // Should prefer chocolate for humans
      expect(recommended!.name, contains('Chocolate'));
    });

    test('should recommend powerful candy for monster enemies', () {
      final monsterEnemy = EnemyCharacter.monster(
        id: 'monster1',
        position: Position(5, 6),
        modelType: MonsterModelType.skeleton,
      );
      final specialCandy = CandyItem.create(CandyType.iceCream, 'ice1');
      player.inventory.clear(); // Clear existing candy
      player.inventory.addCandy(specialCandy);
      
      final recommended = giftSystem.getRecommendedCandy(
        monsterEnemy, 
        player.inventory.candyItems
      );
      
      expect(recommended, isNotNull);
      // Should prefer special ability candy for monsters
      expect(recommended!.effect, CandyEffect.specialAbility);
    });
  });
}