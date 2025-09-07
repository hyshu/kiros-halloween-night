import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/dialogue_event.dart';

void main() {
  group('DialogueEvent', () {
    test('should create basic dialogue event', () {
      const event = DialogueEvent(
        message: 'Hello, world!',
        type: DialogueType.interaction,
      );

      expect(event.message, equals('Hello, world!'));
      expect(event.type, equals(DialogueType.interaction));
      expect(event.canAdvance, isTrue);
      expect(event.canDismiss, isTrue);
      expect(event.speakerName, isNull);
      expect(event.displayDuration, isNull);
    });

    test('should create interaction dialogue event', () {
      final event = DialogueEvent.interaction(
        'Nice to meet you!',
        speakerName: 'Ghost',
      );

      expect(event.message, equals('Nice to meet you!'));
      expect(event.type, equals(DialogueType.interaction));
      expect(event.speakerName, equals('Ghost'));
      expect(event.canAdvance, isTrue);
      expect(event.canDismiss, isTrue);
    });

    test('should create item collection dialogue event', () {
      final event = DialogueEvent.itemCollection('Found candy!');

      expect(event.message, equals('Found candy!'));
      expect(event.type, equals(DialogueType.itemCollection));
      expect(event.displayDuration, equals(const Duration(seconds: 2)));
      expect(event.canAdvance, isTrue);
      expect(event.canDismiss, isTrue);
    });

    test('should create combat dialogue event', () {
      final event = DialogueEvent.combat('Enemy defeated!');

      expect(event.message, equals('Enemy defeated!'));
      expect(event.type, equals(DialogueType.combat));
      expect(event.displayDuration, equals(const Duration(seconds: 3)));
    });

    test('should create story dialogue event', () {
      final event = DialogueEvent.story(
        'The adventure begins...',
        speakerName: 'Narrator',
      );

      expect(event.message, equals('The adventure begins...'));
      expect(event.type, equals(DialogueType.story));
      expect(event.speakerName, equals('Narrator'));
    });

    test('should create boss dialogue event', () {
      final event = DialogueEvent.boss(
        'You dare challenge me?',
        speakerName: 'Boss Monster',
      );

      expect(event.message, equals('You dare challenge me?'));
      expect(event.type, equals(DialogueType.boss));
      expect(event.speakerName, equals('Boss Monster'));
    });

    test('should support equality comparison', () {
      const event1 = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );
      const event2 = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );
      const event3 = DialogueEvent(
        message: 'Different message',
        type: DialogueType.interaction,
      );

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('should have proper toString representation', () {
      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
        speakerName: 'Test Speaker',
      );

      expect(event.toString(), contains('Test message'));
      expect(event.toString(), contains('DialogueType.interaction'));
      expect(event.toString(), contains('Test Speaker'));
    });
  });
}
