import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/core.dart';

// Test implementation of Character for testing
class TestCharacter extends Character {
  TestCharacter({
    required super.id,
    required super.position,
    super.health = 100,
    super.maxHealth = 100,
  }) : super(modelPath: 'test/model.obj');
}

void main() {
  group('Core Architecture Tests', () {
    test('Position should handle basic operations', () {
      const pos1 = Position(5, 10);
      const pos2 = Position(3, 8);

      expect(pos1.x, equals(5));
      expect(pos1.z, equals(10));

      final pos3 = pos1.add(2, 3);
      expect(pos3.x, equals(7));
      expect(pos3.z, equals(13));

      expect(pos1.distanceTo(pos2), equals(4)); // |5-3| + |10-8| = 4
      expect(pos1.isAdjacentTo(Position(5, 11)), isTrue);
      expect(pos1.isAdjacentTo(Position(7, 10)), isFalse);

      final (worldX, worldY, worldZ) = pos1.toWorldCoordinates();
      expect(worldX, equals(5.0 * Position.tileSpacing));
      expect(worldY, equals(0.0));
      expect(worldZ, equals(10.0 * Position.tileSpacing));
    });

    test('TileType should have correct properties', () {
      expect(TileType.floor.blocksMovement, isFalse);
      expect(TileType.wall.blocksMovement, isTrue);
      expect(TileType.obstacle.blocksMovement, isTrue);
      expect(TileType.candy.blocksMovement, isFalse);

      expect(TileType.floor.isWalkable, isTrue);
      expect(TileType.wall.isWalkable, isFalse);

      expect(TileType.candy.isCollectible, isTrue);
      expect(TileType.floor.isCollectible, isFalse);
    });

    test('Character should handle basic operations', () {
      final character = TestCharacter(
        id: 'test-char',
        position: const Position(0, 0),
      );

      expect(character.isAlive, isTrue);
      expect(character.isFullHealth, isTrue);
      expect(character.healthPercentage, equals(1.0));

      character.takeDamage(30);
      expect(character.health, equals(70));
      expect(character.isAlive, isTrue);
      expect(character.healthPercentage, equals(0.7));

      character.heal(20);
      expect(character.health, equals(90));

      final moved = character.moveTo(const Position(1, 1));
      expect(moved, isTrue);
      expect(character.position, equals(const Position(1, 1)));
      expect(character.isIdle, isFalse);

      character.setIdle();
      expect(character.isIdle, isTrue);
    });

    test('GameState should manage game phases correctly', () {
      final gameState = GameState();

      expect(gameState.currentPhase, equals(GamePhase.initializing));
      expect(gameState.isRunning, isFalse);
      expect(gameState.canAcceptInput, isFalse);

      gameState.startGame();
      expect(gameState.isRunning, isTrue);
      expect(gameState.currentPhase, equals(GamePhase.exploration));
      expect(gameState.canAcceptInput, isTrue);
      expect(gameState.canCharactersMove, isTrue);

      gameState.setPhase(GamePhase.combat);
      expect(gameState.isCombatActive, isTrue);
      expect(gameState.canCharactersMove, isFalse);

      gameState.endGameWithVictory();
      expect(gameState.isRunning, isFalse);
      expect(gameState.currentPhase, equals(GamePhase.victory));
      expect(gameState.isGameEnded, isTrue);
    });

    test('GameState should manage characters correctly', () {
      final gameState = GameState();
      final character1 = TestCharacter(
        id: 'char1',
        position: const Position(0, 0),
      );
      final character2 = TestCharacter(
        id: 'char2',
        position: const Position(1, 1),
      );

      gameState.addCharacter(character1);
      gameState.addCharacter(character2);

      expect(gameState.characters.length, equals(2));
      expect(gameState.getCharacter('char1'), equals(character1));

      gameState.setPlayerCharacter(character1);
      expect(gameState.playerCharacter, equals(character1));

      final charactersAtOrigin = gameState.getCharactersAt(
        const Position(0, 0),
      );
      expect(charactersAtOrigin.length, equals(1));
      expect(charactersAtOrigin.first, equals(character1));

      gameState.removeCharacter('char2');
      expect(gameState.characters.length, equals(1));
    });

    test('GameManager should handle basic game operations', () {
      final gameManager = GameManager.instance;

      expect(
        gameManager.gameState.currentPhase,
        equals(GamePhase.initializing),
      );

      // Test position validation
      expect(gameManager.isValidPosition(const Position(5, 5)), isTrue);
      expect(gameManager.isValidPosition(const Position(-1, 0)), isFalse);

      // Test tile type checking
      expect(
        gameManager.getTileTypeAt(const Position(0, 0)),
        equals(TileType.floor),
      );
      expect(gameManager.isPositionBlocked(const Position(0, 0)), isFalse);
    });
  });
}
