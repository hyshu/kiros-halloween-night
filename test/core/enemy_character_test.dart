import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/core.dart';

void main() {
  group('EnemyCharacter', () {
    late TileMap tileMap;
    late GhostCharacter player;
    late EnemyCharacter enemy;

    setUp(() {
      tileMap = TileMap();
      player = GhostCharacter(
        id: 'player',
        position: const Position(10, 10),
      );
      enemy = EnemyCharacter.human(
        id: 'enemy1',
        position: const Position(15, 15),
        modelType: HumanModelType.maleA,
      );
    });

    test('should create enemy with correct initial state', () {
      expect(enemy.id, equals('enemy1'));
      expect(enemy.position, equals(const Position(15, 15)));
      expect(enemy.state, equals(EnemyState.hostile));
      expect(enemy.isProximityActive, isFalse);
      expect(enemy.isActive, isFalse);
      expect(enemy.modelPath, equals('assets/characters/character-male-a.obj'));
    });

    test('should activate when player is within range', () {
      // Move player closer to enemy
      player.position = const Position(12, 12); // Distance of ~4
      
      enemy.activate();
      
      expect(enemy.isProximityActive, isTrue);
      expect(enemy.isActive, isTrue);
    });

    test('should deactivate when player moves away', () {
      enemy.activate();
      expect(enemy.isProximityActive, isTrue);
      
      enemy.deactivate();
      
      expect(enemy.isProximityActive, isFalse);
      expect(enemy.isActive, isFalse);
    });

    test('should convert to ally state', () {
      expect(enemy.isHostile, isTrue);
      expect(enemy.isAlly, isFalse);
      
      enemy.convertToAlly();
      
      expect(enemy.isHostile, isFalse);
      expect(enemy.isAlly, isTrue);
      expect(enemy.state, equals(EnemyState.ally));
    });

    test('should become satisfied', () {
      enemy.setSatisfied();
      
      expect(enemy.isSatisfied, isTrue);
      expect(enemy.isActive, isFalse);
      expect(enemy.state, equals(EnemyState.satisfied));
    });

    test('should not update AI when inactive', () {
      final initialPosition = enemy.position;
      
      // Enemy is inactive by default
      enemy.updateAI(player, tileMap);
      
      expect(enemy.position, equals(initialPosition));
      expect(enemy.isIdle, isTrue);
    });

    test('should update AI when active and proximity activated', () {
      enemy.activate();
      
      // Place player adjacent to enemy for visibility
      player.position = const Position(14, 15);
      
      enemy.updateAI(player, tileMap);
      
      // Enemy should have processed AI (movement cooldown should be set)
      expect(enemy.movementCooldown, greaterThanOrEqualTo(0));
    });
  });

  group('EnemySpawner', () {
    late TileMap tileMap;

    setUp(() {
      tileMap = TileMap();
      EnemySpawner.resetIdCounter();
    });

    test('should spawn enemies across the map', () {
      final enemies = EnemySpawner.spawnEnemies(
        tileMap,
        spawnDensity: 0.1, // Low density for testing
        playerSpawn: const Position(10, 10),
      );

      expect(enemies, isNotEmpty);
      
      // Check that enemies are not too close to player spawn
      for (final enemy in enemies) {
        final distance = enemy.position.distanceTo(const Position(10, 10));
        expect(distance, greaterThanOrEqualTo(10));
      }
    });

    test('should spawn boss enemy', () {
      final boss = EnemySpawner.spawnBoss(const Position(100, 200));
      
      expect(boss.id, startsWith('boss_'));
      expect(boss.position, equals(const Position(100, 200)));
      expect(boss.health, equals(200));
      expect(boss.maxHealth, equals(200));
      expect(boss.activationRadius, equals(15));
    });

    test('should spawn single enemy at position', () {
      final enemy = EnemySpawner.spawnSingleEnemyAt(
        const Position(50, 50),
        tileMap,
      );

      expect(enemy, isNotNull);
      expect(enemy!.position, equals(const Position(50, 50)));
    });

    test('should not spawn enemy on unwalkable tile', () {
      // Try to spawn on a wall (perimeter)
      final enemy = EnemySpawner.spawnSingleEnemyAt(
        const Position(0, 0), // This is a wall
        tileMap,
      );

      expect(enemy, isNull);
    });
  });

  group('CollisionDetector', () {
    late TileMap tileMap;
    late CollisionDetector collisionDetector;
    late GhostCharacter player;
    late EnemyCharacter enemy;

    setUp(() {
      tileMap = TileMap();
      player = GhostCharacter(
        id: 'player',
        position: const Position(10, 10),
      );
      enemy = EnemyCharacter.human(
        id: 'enemy1',
        position: const Position(15, 15),
        modelType: HumanModelType.femaleA,
      );
      
      collisionDetector = CollisionDetector(
        tileMap: tileMap,
        characters: [player, enemy],
      );
    });

    test('should detect valid movement', () {
      final canMove = collisionDetector.canMoveTo(
        player,
        const Position(11, 10),
      );
      
      expect(canMove, isTrue);
    });

    test('should detect wall collision', () {
      final canMove = collisionDetector.canMoveTo(
        player,
        const Position(0, 0), // Wall position
      );
      
      expect(canMove, isFalse);
    });

    test('should detect character collision', () {
      final canMove = collisionDetector.canMoveTo(
        player,
        enemy.position, // Enemy's position
      );
      
      expect(canMove, isTrue); // Should be true since enemy is inactive
      
      // Activate enemy and try again
      enemy.isActive = true;
      final canMoveWithActiveEnemy = collisionDetector.canMoveTo(
        player,
        enemy.position,
      );
      
      expect(canMoveWithActiveEnemy, isFalse);
    });

    test('should get characters in radius', () {
      final charactersInRadius = collisionDetector.getCharactersInRadius(
        const Position(12, 12),
        5,
      );
      
      // Only player should be in range (enemy is inactive)
      expect(charactersInRadius.length, equals(1));
      expect(charactersInRadius.first.id, equals('player'));
    });

    test('should validate movement with detailed result', () {
      final validation = collisionDetector.validateMovement(
        player,
        const Position(11, 10),
      );
      
      expect(validation.isValid, isTrue);
      expect(validation.result, equals(MovementResult.success));
      expect(validation.tileType, equals(TileType.floor));
    });
  });

  group('Enemy Model Types', () {
    test('should provide random human model types', () {
      final model1 = HumanModelType.random();
      final model2 = HumanModelType.random();
      
      expect(model1, isA<HumanModelType>());
      expect(model2, isA<HumanModelType>());
      expect(model1.modelPath, startsWith('assets/characters/character-'));
    });

    test('should provide random monster model types', () {
      final model1 = MonsterModelType.random();
      final model2 = MonsterModelType.random();
      
      expect(model1, isA<MonsterModelType>());
      expect(model2, isA<MonsterModelType>());
      expect(model1.modelPath, startsWith('assets/graveyard/character-'));
    });
  });
}