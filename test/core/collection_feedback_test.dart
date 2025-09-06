import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/collection_feedback.dart';
import '../../lib/core/candy_collection_system.dart';
import '../../lib/core/candy_item.dart';
import '../../lib/core/ghost_character.dart';
import '../../lib/core/position.dart';

void main() {
  group('CollectionFeedback', () {
    test('should create feedback with correct properties', () {
      final position = Position(10, 10);
      final feedback = CollectionFeedback(
        type: FeedbackType.text,
        message: 'Test Message',
        position: position,
        durationMs: 1000,
        color: '#FF0000',
        scale: 1.5,
      );
      
      expect(feedback.type, equals(FeedbackType.text));
      expect(feedback.message, equals('Test Message'));
      expect(feedback.position, equals(position));
      expect(feedback.durationMs, equals(1000));
      expect(feedback.color, equals('#FF0000'));
      expect(feedback.scale, equals(1.5));
      expect(feedback.isActive, isTrue);
      expect(feedback.isExpired, isFalse);
    });

    test('should calculate progress correctly', () {
      final feedback = CollectionFeedback(
        type: FeedbackType.text,
        message: 'Test',
        position: Position(0, 0),
        durationMs: 1000,
      );
      
      // Progress should start at 0
      expect(feedback.progress, equals(0.0));
      
      // Wait a bit and check progress (this is approximate due to timing)
      Future.delayed(Duration(milliseconds: 100), () {
        expect(feedback.progress, greaterThan(0.0));
        expect(feedback.progress, lessThan(1.0));
      });
    });

    test('should detect expiration', () {
      final feedback = CollectionFeedback(
        type: FeedbackType.text,
        message: 'Test',
        position: Position(0, 0),
        durationMs: 1, // Very short duration
      );
      
      // Should expire very quickly
      Future.delayed(Duration(milliseconds: 10), () {
        expect(feedback.isExpired, isTrue);
      });
    });

    test('should deactivate feedback', () {
      final feedback = CollectionFeedback(
        type: FeedbackType.text,
        message: 'Test',
        position: Position(0, 0),
      );
      
      expect(feedback.isActive, isTrue);
      feedback.deactivate();
      expect(feedback.isActive, isFalse);
    });

    test('should have meaningful toString', () {
      final feedback = CollectionFeedback(
        type: FeedbackType.floatingText,
        message: 'Health Boost',
        position: Position(5, 5),
      );
      
      final str = feedback.toString();
      expect(str, contains('floatingText'));
      expect(str, contains('Health Boost'));
      expect(str, contains('5, 5'));
    });
  });

  group('CollectionFeedbackManager', () {
    late CollectionFeedbackManager feedbackManager;
    late GhostCharacter character;

    setUp(() {
      feedbackManager = CollectionFeedbackManager();
      character = GhostCharacter(
        id: 'test_ghost',
        position: Position(5, 5),
        health: 80,
        maxHealth: 100,
      );
    });

    test('should start empty', () {
      expect(feedbackManager.activeFeedback.isEmpty, isTrue);
    });

    test('should process successful collection event', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1');
      final event = CandyCollectionEvent(
        candy: candy,
        position: Position(10, 10),
        character: character,
        successful: true,
      );
      
      feedbackManager.processCollectionEvent(event);
      
      expect(feedbackManager.activeFeedback.isNotEmpty, isTrue);
      
      final feedback = feedbackManager.activeFeedback.first;
      expect(feedback.message, contains('Health'));
      expect(feedback.type, equals(FeedbackType.floatingText));
      expect(feedback.color, equals('#00FF00')); // Green for health boost
    });

    test('should process failed collection event', () {
      final candy = CandyItem.create(CandyType.candyBar, 'candy_1');
      final event = CandyCollectionEvent(
        candy: candy,
        position: Position(10, 10),
        character: character,
        successful: false,
        failureReason: 'Inventory full',
      );
      
      feedbackManager.processCollectionEvent(event);
      
      expect(feedbackManager.activeFeedback.isNotEmpty, isTrue);
      
      final feedback = feedbackManager.activeFeedback.first;
      expect(feedback.message, equals('Inventory Full!'));
      expect(feedback.type, equals(FeedbackType.text));
      expect(feedback.color, equals('#FF4444')); // Red for failure
    });

    test('should create appropriate messages for different candy effects', () {
      final testCases = [
        (CandyType.candyBar, CandyEffect.healthBoost, '+20 Health'),
        (CandyType.chocolate, CandyEffect.maxHealthIncrease, '+10 Max Health'),
        (CandyType.cookie, CandyEffect.speedIncrease, 'Speed Boost!'),
        (CandyType.cupcake, CandyEffect.allyStrength, 'Ally Power!'),
        (CandyType.iceCream, CandyEffect.specialAbility, 'Special Power!'),
        (CandyType.lollipop, CandyEffect.statModification, 'Stat Boost!'),
      ];
      
      for (final (candyType, expectedEffect, expectedMessage) in testCases) {
        final candy = CandyItem.create(candyType, 'test');
        expect(candy.effect, equals(expectedEffect));
        
        final event = CandyCollectionEvent(
          candy: candy,
          position: Position(0, 0),
          character: character,
          successful: true,
        );
        
        feedbackManager.clearAll();
        feedbackManager.processCollectionEvent(event);
        
        final feedback = feedbackManager.activeFeedback.first;
        expect(feedback.message, equals(expectedMessage));
      }
    });

    test('should use appropriate colors for different effects', () {
      final testCases = [
        (CandyType.candyBar, '#00FF00'),    // Green for health
        (CandyType.chocolate, '#00FFFF'),   // Cyan for max health
        (CandyType.cookie, '#FFFF00'),      // Yellow for speed
        (CandyType.cupcake, '#FF8800'),     // Orange for ally strength
        (CandyType.iceCream, '#FF00FF'),    // Magenta for special ability
        (CandyType.lollipop, '#8800FF'),    // Purple for stat modification
      ];
      
      for (final (candyType, expectedColor) in testCases) {
        final candy = CandyItem.create(candyType, 'test');
        final event = CandyCollectionEvent(
          candy: candy,
          position: Position(0, 0),
          character: character,
          successful: true,
        );
        
        feedbackManager.clearAll();
        feedbackManager.processCollectionEvent(event);
        
        final feedback = feedbackManager.activeFeedback.first;
        expect(feedback.color, equals(expectedColor));
      }
    });

    test('should create particle effects for special candy', () {
      final specialCandy = CandyItem.create(CandyType.iceCream, 'special');
      final event = CandyCollectionEvent(
        candy: specialCandy,
        position: Position(10, 10),
        character: character,
        successful: true,
      );
      
      feedbackManager.processCollectionEvent(event);
      
      // Should create both floating text and particle effect
      expect(feedbackManager.activeFeedback.length, equals(2));
      
      final particleEffect = feedbackManager.activeFeedback
          .firstWhere((f) => f.type == FeedbackType.particles);
      expect(particleEffect.message, equals('✨'));
      expect(particleEffect.color, equals('#FFD700')); // Gold
    });

    test('should create custom feedback', () {
      feedbackManager.createCustomFeedback(
        message: 'Custom Message',
        position: Position(15, 15),
        type: FeedbackType.flash,
        durationMs: 3000,
        color: '#FFFFFF',
        scale: 2.0,
      );
      
      expect(feedbackManager.activeFeedback.length, equals(1));
      
      final feedback = feedbackManager.activeFeedback.first;
      expect(feedback.message, equals('Custom Message'));
      expect(feedback.type, equals(FeedbackType.flash));
      expect(feedback.durationMs, equals(3000));
      expect(feedback.color, equals('#FFFFFF'));
      expect(feedback.scale, equals(2.0));
    });

    test('should limit active feedback count', () {
      final limitedManager = CollectionFeedbackManager(maxActiveFeedback: 3);
      
      // Add more feedback than the limit
      for (int i = 0; i < 5; i++) {
        limitedManager.createCustomFeedback(
          message: 'Message $i',
          position: Position(i, i),
        );
      }
      
      expect(limitedManager.activeFeedback.length, equals(3));
    });

    test('should get feedback at position', () {
      final position = Position(20, 20);
      
      feedbackManager.createCustomFeedback(
        message: 'At Position',
        position: position,
      );
      
      feedbackManager.createCustomFeedback(
        message: 'Elsewhere',
        position: Position(30, 30),
      );
      
      final feedbackAtPosition = feedbackManager.getFeedbackAt(position);
      expect(feedbackAtPosition.length, equals(1));
      expect(feedbackAtPosition.first.message, equals('At Position'));
    });

    test('should get feedback by type', () {
      feedbackManager.createCustomFeedback(
        message: 'Text 1',
        position: Position(0, 0),
        type: FeedbackType.text,
      );
      
      feedbackManager.createCustomFeedback(
        message: 'Text 2',
        position: Position(1, 1),
        type: FeedbackType.text,
      );
      
      feedbackManager.createCustomFeedback(
        message: 'Flash',
        position: Position(2, 2),
        type: FeedbackType.flash,
      );
      
      final textFeedback = feedbackManager.getFeedbackByType(FeedbackType.text);
      expect(textFeedback.length, equals(2));
      
      final flashFeedback = feedbackManager.getFeedbackByType(FeedbackType.flash);
      expect(flashFeedback.length, equals(1));
    });

    test('should clear all feedback', () {
      feedbackManager.createCustomFeedback(
        message: 'Test 1',
        position: Position(0, 0),
      );
      
      feedbackManager.createCustomFeedback(
        message: 'Test 2',
        position: Position(1, 1),
      );
      
      expect(feedbackManager.activeFeedback.length, equals(2));
      
      feedbackManager.clearAll();
      expect(feedbackManager.activeFeedback.isEmpty, isTrue);
    });

    test('should update and cleanup expired feedback', () {
      // Create feedback with very short duration
      feedbackManager.createCustomFeedback(
        message: 'Short lived',
        position: Position(0, 0),
        durationMs: 1,
      );
      
      expect(feedbackManager.activeFeedback.length, equals(1));
      
      // Wait for expiration and update
      Future.delayed(Duration(milliseconds: 10), () {
        feedbackManager.update();
        expect(feedbackManager.activeFeedback.isEmpty, isTrue);
      });
    });

    test('should have meaningful toString', () {
      feedbackManager.createCustomFeedback(
        message: 'Test',
        position: Position(0, 0),
      );
      
      final str = feedbackManager.toString();
      expect(str, contains('CollectionFeedbackManager'));
      expect(str, contains('1 active'));
    });
  });
}