import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/scene/grid_scene_manager.dart';
import 'package:kiro_halloween_game/core/world_generator.dart';
import 'package:kiro_halloween_game/core/tile_map.dart';
import 'package:kiro_halloween_game/core/position.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('GridSceneManager Integration Tests', () {
    test('should create scene manager with tile map', () {
      final tileMap = TileMap();
      tileMap.setPlayerSpawn(Position(10, 10));
      tileMap.setBossLocation(Position(90, 100));

      final sceneManager = GridSceneManager.withTileMap(tileMap);

      expect(sceneManager.tileMap, equals(tileMap));
      expect(sceneManager.cameraTarget.x, equals(10.0 * Position.tileSpacing));
      expect(sceneManager.cameraTarget.z, equals(10.0 * Position.tileSpacing));
    });

    test('should initialize with generated world', () {
      final worldGenerator = WorldGenerator(seed: 123, isTestMode: true);
      final tileMap = worldGenerator.generateWorld();

      final sceneManager = GridSceneManager.withTileMap(tileMap);

      // Should have tile map set
      expect(sceneManager.tileMap, equals(tileMap));
      expect(sceneManager.tileMap!.playerSpawn, isNotNull);
      expect(sceneManager.tileMap!.bossLocation, isNotNull);
    });

    test('should handle viewport-based object rendering', () {
      final tileMap = TileMap();
      tileMap.setPlayerSpawn(Position(50, 100)); // Center of world

      final sceneManager = GridSceneManager.withTileMap(tileMap);

      // Camera should be positioned at spawn
      expect(sceneManager.cameraTarget.x, equals(50.0 * Position.tileSpacing));
      expect(sceneManager.cameraTarget.z, equals(100.0 * Position.tileSpacing));
    });

    test('should update camera target', () {
      final tileMap = TileMap();
      final sceneManager = GridSceneManager.withTileMap(tileMap);

      final newTarget = Vector3(50, 0, 100);
      sceneManager.updateCameraTarget(newTarget);

      expect(sceneManager.cameraTarget, equals(newTarget));
    });

    test('should handle large world bounds checking', () {
      final tileMap = TileMap();
      final sceneManager = GridSceneManager.withTileMap(tileMap);

      // Should accept valid positions within tile map bounds
      expect(() => sceneManager.getObjectAt(50, 100), returnsNormally);
      expect(
        () => sceneManager.getObjectAt(
          TileMap.worldWidth - 1,
          TileMap.worldHeight - 1,
        ),
        returnsNormally,
      );

      // Should return null for positions outside bounds
      expect(sceneManager.getObjectAt(-1, -1), isNull);
      expect(
        sceneManager.getObjectAt(TileMap.worldWidth, TileMap.worldHeight),
        isNull,
      );
    });
  });
}
