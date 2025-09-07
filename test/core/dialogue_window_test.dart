import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/dialogue_window.dart';
import '../../lib/core/dialogue_event.dart';

void main() {
  group('DialogueWindow', () {
    late DialogueWindow dialogueWindow;

    setUp(() {
      dialogueWindow = DialogueWindow();
    });

    test('should initialize with inactive state', () {
      expect(dialogueWindow.isActive, isFalse);
      expect(dialogueWindow.currentEvent, isNull);
      expect(dialogueWindow.canAdvance, isFalse);
      expect(dialogueWindow.canDismiss, isFalse);
    });

    test('should display dialogue event', () {
      bool showCalled = false;
      dialogueWindow.setCallbacks(onShow: () => showCalled = true);

      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );

      dialogueWindow.displayDialogue(event);

      expect(dialogueWindow.isActive, isTrue);
      expect(dialogueWindow.currentEvent, equals(event));
      expect(dialogueWindow.canAdvance, isTrue);
      expect(dialogueWindow.canDismiss, isTrue);
      expect(showCalled, isTrue);
    });

    test('should advance dialogue', () {
      bool advanceCalled = false;
      bool hideCalled = false;
      dialogueWindow.setCallbacks(
        onAdvance: () => advanceCalled = true,
        onHide: () => hideCalled = true,
      );

      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );

      dialogueWindow.displayDialogue(event);
      dialogueWindow.advanceDialogue();

      expect(dialogueWindow.isActive, isFalse);
      expect(dialogueWindow.currentEvent, isNull);
      expect(advanceCalled, isTrue);
      expect(hideCalled, isTrue);
    });

    test('should dismiss dialogue', () {
      bool dismissCalled = false;
      bool hideCalled = false;
      dialogueWindow.setCallbacks(
        onDismiss: () => dismissCalled = true,
        onHide: () => hideCalled = true,
      );

      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );

      dialogueWindow.displayDialogue(event);
      dialogueWindow.dismissDialogue();

      expect(dialogueWindow.isActive, isFalse);
      expect(dialogueWindow.currentEvent, isNull);
      expect(dismissCalled, isTrue);
      expect(hideCalled, isTrue);
    });

    test('should not advance when canAdvance is false', () {
      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
        canAdvance: false,
      );

      dialogueWindow.displayDialogue(event);
      dialogueWindow.advanceDialogue();

      expect(dialogueWindow.isActive, isTrue);
      expect(dialogueWindow.currentEvent, equals(event));
    });

    test('should not dismiss when canDismiss is false', () {
      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
        canDismiss: false,
      );

      dialogueWindow.displayDialogue(event);
      dialogueWindow.dismissDialogue();

      expect(dialogueWindow.isActive, isTrue);
      expect(dialogueWindow.currentEvent, equals(event));
    });

    test('should auto-dismiss after duration', () {
      final event = DialogueEvent.itemCollection('Found candy!');
      dialogueWindow.displayDialogue(event);

      expect(dialogueWindow.isActive, isTrue);
      expect(dialogueWindow.shouldAutoDismiss, isFalse);

      // Simulate time passing
      Future.delayed(const Duration(seconds: 3), () {
        dialogueWindow.update();
        expect(dialogueWindow.isActive, isFalse);
      });
    });

    test('should get display text without speaker', () {
      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );

      dialogueWindow.displayDialogue(event);
      expect(dialogueWindow.getDisplayText(), equals('Test message'));
    });

    test('should get display text with speaker', () {
      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
        speakerName: 'Ghost',
      );

      dialogueWindow.displayDialogue(event);
      expect(dialogueWindow.getDisplayText(), equals('Ghost: Test message'));
    });

    test('should get dialogue type', () {
      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.combat,
      );

      dialogueWindow.displayDialogue(event);
      expect(dialogueWindow.getDialogueType(), equals(DialogueType.combat));
    });

    test('should clear all state', () {
      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );

      dialogueWindow.displayDialogue(event);
      dialogueWindow.clear();

      expect(dialogueWindow.isActive, isFalse);
      expect(dialogueWindow.currentEvent, isNull);
      expect(dialogueWindow.getDisplayText(), isEmpty);
    });
  });
}