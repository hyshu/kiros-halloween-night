import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/candy_collection_system.dart';
import '../../lib/core/candy_item.dart';
import '../../lib/core/ghost_character.dart';
import '../../lib/core/position.dart';
import '../../lib/core/tile_map.dart';
import '../../lib/core/tile_type.dart';
import '../../lib/core/inventory.dart';

void main() {
  group('CandyCollectionEvent', () {
    test('should create successful collection event', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1');
      final character = GhostCharacter(id: 'ghost', position: Position(0, 0));
      final position = Position(5, 5);
      
      final event = CandyCollectionEvent(
        candy: candy,
        position: position,
        character: character,
        successful: true,
      );
      
      expect(event.successful, isTrue);
      expect(event.failureReason, isNull);
      expect(event.candy, equals(candy));
      expect(event.position, equals(position));
      expect(event.character, equals(character));
    });

    test('should create failed collection event', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1');
      final character = GhostCharacter(id: 'ghost', position: Position(0, 0));
      final position = Position(5, 5);
      
      final event = CandyCollectionEvent(
        candy: candy,
        position: position,
        character: character,
        successful: false,
        failureReason: 'Inventory full',
      );
      
      expect(event.successful, isFalse);
      expect(event.failureReason, equals('Inventory full'));
    });

    test('should have meaningful toString', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1');
      final character = GhostCharacter(id: 'ghost', position: Position(0, 0));
      final position = Position(5, 5);
      
      final successEvent = CandyCollectionEvent(
        candy: candy,
        position: position,
        character: character,
        successful: true,
      );
      
      final failEvent = CandyCollectionEvent(
        candy: candy,
        position: position,
        character: character,
        successful: false,
        failureReason: 'Test failure',
      );
      
      expect(successEvent.toString(), contains('Collected'));
      expect(successEvent.toString(), contains('Candy Bar'));
      expect(failEvent.toString(), contains('Failed'));
      expect(failEvent.toString(), contains('Test failure'));
    });
  });

  group('CandyCollectionSystem', () {
    late CandyCollectionSystem collectionSystem;
    late GhostCharacter character;
    late TileMap tileMap;

    setUp(() {
      collectionSystem = CandyCollectionSystem();
      character = GhostCharacter(
        id: 'test_ghost',
        position: Position(5, 5),
        health: 80,
        maxHealth: 100,
      );
      tileMap = TileMap();
    });

    test('should start empty', () {
      expect(collectionSystem.allCandy.isEmpty, isTrue);
      expect(collectionSystem.recentEvents.isEmpty, isTrue);
      expect(collectionSystem.remainingCandyCount, equals(0));
    });

    test('should add candy items', () {
      final candy1 = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(10, 10));
      final candy2 = CandyItem.create(CandyType.chocolate, 'candy_2', position: Position(12, 12));
      
      collectionSystem.addCandy([candy1, candy2]);
      
      expect(collectionSystem.allCandy.length, equals(2));
      expect(collectionSystem.remainingCandyCount, equals(2));
      expect(collectionSystem.getCandyAt(Position(10, 10)), equals(candy1));
      expect(collectionSystem.getCandyAt(Position(12, 12)), equals(candy2));
    });

    test('should add single candy item', () {
      final candy = CandyItem.create(CandyType.donut, 'candy_1', position: Position(8, 8));
      
      collectionSystem.addSingleCandy(candy);
      
      expect(collectionSystem.allCandy.length, equals(1));
      expect(collectionSystem.getCandyAt(Position(8, 8)), equals(candy));
    });

    test('should remove candy items', () {
      final candy = CandyItem.create(CandyType.cookie, 'candy_1', position: Position(7, 7));
      
      collectionSystem.addSingleCandy(candy);
      expect(collectionSystem.allCandy.length, equals(1));
      
      collectionSystem.removeCandy(candy);
      expect(collectionSystem.allCandy.isEmpty, isTrue);
      expect(collectionSystem.getCandyAt(Position(7, 7)), isNull);
    });

    test('should check for candy at position', () {
      final candy = CandyItem.create(CandyType.muffin, 'candy_1', position: Position(6, 6));
      
      expect(collectionSystem.hasCandyAt(Position(6, 6)), isFalse);
      
      collectionSystem.addSingleCandy(candy);
      expect(collectionSystem.hasCandyAt(Position(6, 6)), isTrue);
      expect(collectionSystem.hasCandyAt(Position(7, 7)), isFalse);
    });

    test('should not return collected candy', () {
      final candy = CandyItem.create(CandyType.lollipop, 'candy_1', position: Position(9, 9));
      
      collectionSystem.addSingleCandy(candy);
      expect(collectionSystem.getCandyAt(Position(9, 9)), equals(candy));
      
      candy.collect();
      expect(collectionSystem.getCandyAt(Position(9, 9)), isNull);
      expect(collectionSystem.remainingCandyCount, equals(0));
    });

    test('should attempt collection successfully', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(5, 5));
      
      collectionSystem.addSingleCandy(candy);
      tileMap.setTileAt(Position(5, 5), TileType.candy);
      
      final event = collectionSystem.attemptCollection(character, tileMap);
      
      expect(event, isNotNull);
      expect(event!.successful, isTrue);
      expect(event.candy, equals(candy));
      expect(candy.isCollected, isTrue);
      expect(tileMap.getTileAt(Position(5, 5)), equals(TileType.floor));
      expect(character.inventory.count, equals(1));
      expect(collectionSystem.recentEvents.length, equals(1));
    });

    test('should attempt collection with full inventory', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(5, 5));
      
      // Fill character's inventory
      final fullInventory = Inventory(maxCapacity: 1);
      fullInventory.addCandy(CandyItem.create(CandyType.donut, 'existing'));
      character = GhostCharacter(
        id: 'test_ghost',
        position: Position(5, 5),
        inventory: fullInventory,
      );
      
      collectionSystem.addSingleCandy(candy);
      tileMap.setTileAt(Position(5, 5), TileType.candy);
      
      final event = collectionSystem.attemptCollection(character, tileMap);
      
      expect(event, isNotNull);
      expect(event!.successful, isFalse);
      expect(event.failureReason, equals('Inventory full'));
      expect(candy.isCollected, isFalse);
      expect(tileMap.getTileAt(Position(5, 5)), equals(TileType.candy)); // Tile unchanged
    });

    test('should return null when no candy at position', () {
      final event = collectionSystem.attemptCollection(character, tileMap);
      expect(event, isNull);
    });

    test('should process movement and collect candy', () {
      final candy = CandyItem.create(CandyType.chocolate, 'candy_1', position: Position(5, 5));
      
      collectionSystem.addSingleCandy(candy);
      tileMap.setTileAt(Position(5, 5), TileType.candy);
      
      final event = collectionSystem.processMovement(character, tileMap);
      
      expect(event, isNotNull);
      expect(event!.successful, isTrue);
      expect(candy.isCollected, isTrue);
    });

    test('should return null when moving to non-candy tile', () {
      tileMap.setTileAt(Position(5, 5), TileType.floor);
      
      final event = collectionSystem.processMovement(character, tileMap);
      expect(event, isNull);
    });

    test('should get candy by type', () {
      final candy1 = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(10, 10));
      final candy2 = CandyItem.create(CandyType.candyBar, 'candy_2', position: Position(11, 11));
      final candy3 = CandyItem.create(CandyType.chocolate, 'candy_3', position: Position(12, 12));
      
      collectionSystem.addCandy([candy1, candy2, candy3]);
      
      final candyBars = collectionSystem.getCandyByType(CandyType.candyBar);
      expect(candyBars.length, equals(2));
      expect(candyBars, contains(candy1));
      expect(candyBars, contains(candy2));
      
      final chocolates = collectionSystem.getCandyByType(CandyType.chocolate);
      expect(chocolates.length, equals(1));
      expect(chocolates, contains(candy3));
    });

    test('should get candy by effect', () {
      final healthCandy1 = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(10, 10));
      final healthCandy2 = CandyItem.create(CandyType.donut, 'candy_2', position: Position(11, 11));
      final speedCandy = CandyItem.create(CandyType.cookie, 'candy_3', position: Position(12, 12));
      
      collectionSystem.addCandy([healthCandy1, healthCandy2, speedCandy]);
      
      final healthCandies = collectionSystem.getCandyByEffect(CandyEffect.healthBoost);
      expect(healthCandies.length, equals(2));
      
      final speedCandies = collectionSystem.getCandyByEffect(CandyEffect.speedIncrease);
      expect(speedCandies.length, equals(1));
    });

    test('should get candy near position', () {
      final candy1 = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(10, 10));
      final candy2 = CandyItem.create(CandyType.chocolate, 'candy_2', position: Position(12, 12));
      final candy3 = CandyItem.create(CandyType.donut, 'candy_3', position: Position(20, 20));
      
      collectionSystem.addCandy([candy1, candy2, candy3]);
      
      final nearCandy = collectionSystem.getCandyNearPosition(Position(11, 11), 3);
      expect(nearCandy.length, equals(2)); // candy1 and candy2 are within distance 3
      expect(nearCandy, contains(candy1));
      expect(nearCandy, contains(candy2));
      expect(nearCandy, isNot(contains(candy3)));
    });

    test('should get collection statistics', () {
      final candy1 = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(10, 10));
      final candy2 = CandyItem.create(CandyType.chocolate, 'candy_2', position: Position(11, 11));
      
      collectionSystem.addCandy([candy1, candy2]);
      
      // Collect one candy
      candy1.collect();
      
      final stats = collectionSystem.getCollectionStatistics();
      
      expect(stats['totalCandy'], equals(2));
      expect(stats['collectedCandy'], equals(1));
      expect(stats['remainingCandy'], equals(1));
      expect(stats['collectionRate'], equals(0.5));
      expect(stats['collectedByType'], isA<Map<String, int>>());
      expect(stats['collectedByEffect'], isA<Map<String, int>>());
    });

    test('should track recent events', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(5, 5));
      
      collectionSystem.addSingleCandy(candy);
      tileMap.setTileAt(Position(5, 5), TileType.candy);
      
      collectionSystem.attemptCollection(character, tileMap);
      
      expect(collectionSystem.recentEvents.length, equals(1));
      expect(collectionSystem.lastSuccessfulCollection, isNotNull);
      expect(collectionSystem.lastFailedCollection, isNull);
    });

    test('should limit recent events', () {
      final limitedSystem = CandyCollectionSystem(maxRecentEvents: 2);
      
      for (int i = 0; i < 5; i++) {
        final position = Position(10 + i, 10 + i); // Use positions away from perimeter
        final candy = CandyItem.create(CandyType.candyBar, 'candy_$i', position: position);
        limitedSystem.addSingleCandy(candy);
        tileMap.setTileAt(position, TileType.candy);
        
        character.position = position;
        limitedSystem.attemptCollection(character, tileMap);
      }
      
      expect(limitedSystem.recentEvents.length, equals(2));
    });

    test('should check for recent collection', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(5, 5));
      
      expect(collectionSystem.hasRecentCollection(), isFalse);
      
      collectionSystem.addSingleCandy(candy);
      tileMap.setTileAt(Position(5, 5), TileType.candy);
      collectionSystem.attemptCollection(character, tileMap);
      
      expect(collectionSystem.hasRecentCollection(), isTrue);
    });

    test('should clear recent events', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(5, 5));
      
      collectionSystem.addSingleCandy(candy);
      tileMap.setTileAt(Position(5, 5), TileType.candy);
      collectionSystem.attemptCollection(character, tileMap);
      
      expect(collectionSystem.recentEvents.length, equals(1));
      
      collectionSystem.clearRecentEvents();
      expect(collectionSystem.recentEvents.isEmpty, isTrue);
    });

    test('should reset system', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1', position: Position(5, 5));
      
      collectionSystem.addSingleCandy(candy);
      tileMap.setTileAt(Position(5, 5), TileType.candy);
      collectionSystem.attemptCollection(character, tileMap);
      
      expect(collectionSystem.allCandy.length, equals(1));
      expect(collectionSystem.recentEvents.length, equals(1));
      
      collectionSystem.reset();
      
      expect(collectionSystem.allCandy.isEmpty, isTrue);
      expect(collectionSystem.recentEvents.isEmpty, isTrue);
      expect(collectionSystem.remainingCandyCount, equals(0));
    });
  });
}