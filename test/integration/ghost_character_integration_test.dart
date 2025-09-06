import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/ghost_character.dart';
import '../../lib/core/position.dart';
import '../../lib/core/tile_map.dart';
import '../../lib/scene/grid_scene_manager.dart';

void main() {
  group('GhostCharacter Integration Tests', () {
    late GhostCharacter ghostCharacter;
    late TileMap tileMap;
    late GridSceneManager sceneManager;

    setUp(() {
      // Create test tile map
      tileMap = TileMap();
      tileMap.setPlayerSpawn(const Position(10, 10));
      
      // Create ghost character
      ghostCharacter = GhostCharacter(
        id: 'test_kiro',
        position: const Position(10, 10),
        health: 100,
        maxHealth: 100,
      );
      
      // Create scene manager
      sceneManager = GridSceneManager.withTileMap(tileMap);
    });

    test('should integrate with scene manager correctly', () async {
      // Add ghost character to scene
      await sceneManager.addGhostCharacter(ghostCharacter);
      
      // Verify character is in scene
      expect(sceneManager.ghostCharacter, equals(ghostCharacter));
      
      // Verify character object is in all objects
      final allObjects = sceneManager.allObjects;
      expect(allObjects.any((obj) => obj.displayName == 'test_kiro'), isTrue);
    });

    test('should update scene when character moves', () async {
      // Add ghost character to scene
      await sceneManager.addGhostCharacter(ghostCharacter);
      
      // Move character
      final moved = ghostCharacter.attemptMove(Direction.south, tileMap);
      expect(moved, isTrue);
      expect(ghostCharacter.position, equals(const Position(10, 11)));
      
      // Update scene manager
      sceneManager.updateGhostCharacterPosition();
      
      // Verify character object position is updated
      final allObjects = sceneManager.allObjects;
      final characterObject = allObjects.firstWhere((obj) => obj.displayName == 'test_kiro');
      expect(characterObject.gridX, equals(10));
      expect(characterObject.gridZ, equals(11));
    });

    test('should update camera to follow character', () async {
      // Add ghost character to scene
      await sceneManager.addGhostCharacter(ghostCharacter);
      
      // Initial camera target should be at character position
      expect(sceneManager.cameraTarget.x, equals(20.0)); // 10 * 2.0
      expect(sceneManager.cameraTarget.z, equals(20.0)); // 10 * 2.0
      
      // Move character
      ghostCharacter.attemptMove(Direction.east, tileMap);
      sceneManager.updateGhostCharacterPosition();
      
      // Camera should follow
      expect(sceneManager.cameraTarget.x, equals(22.0)); // 11 * 2.0
      expect(sceneManager.cameraTarget.z, equals(20.0)); // 10 * 2.0
    });

    test('should handle character abilities', () {
      // Add abilities
      ghostCharacter.addAbility('speedBoost', 2);
      ghostCharacter.addAbility('healthBoost', 25);
      
      // Verify abilities
      expect(ghostCharacter.hasAbility('speedBoost'), isTrue);
      expect(ghostCharacter.getAbility<int>('speedBoost'), equals(2));
      expect(ghostCharacter.hasAbility('healthBoost'), isTrue);
      
      // Remove ability
      ghostCharacter.removeAbility('speedBoost');
      expect(ghostCharacter.hasAbility('speedBoost'), isFalse);
    });

    test('should maintain character state correctly', () {
      // Initial state
      expect(ghostCharacter.isIdle, isTrue);
      expect(ghostCharacter.isActive, isTrue);
      expect(ghostCharacter.canMove, isTrue);
      expect(ghostCharacter.facingDirection, isNull);
      
      // After movement
      ghostCharacter.attemptMove(Direction.north, tileMap);
      expect(ghostCharacter.isIdle, isFalse);
      expect(ghostCharacter.facingDirection, equals(Direction.north));
      
      // Set to idle
      ghostCharacter.setIdle();
      expect(ghostCharacter.isIdle, isTrue);
      expect(ghostCharacter.facingDirection, isNull);
    });
  });
}