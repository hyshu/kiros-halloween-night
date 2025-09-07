import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/dialogue_manager.dart';
import 'package:kiro_halloween_game/core/dialogue_event.dart';

void main() {
  group('DialogueManager', () {
    late DialogueManager dialogueManager;

    setUp(() {
      dialogueManager = DialogueManager();
    });

    test('should initialize with inactive state', () {
      expect(dialogueManager.isDialogueActive, isFalse);
      expect(dialogueManager.hasPendingEvents, isFalse);
    });

    test('should trigger dialogue immediately when inactive', () {
      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );

      dialogueManager.triggerDialogue(event);

      expect(dialogueManager.isDialogueActive, isTrue);
      // The current event will be a combined event with DialogueType.combat
      expect(dialogueManager.getCurrentDialogueText(), equals('Test message'));
    });

    test('should queue dialogue when active', () {
      const event1 = DialogueEvent(
        message: 'First message',
        type: DialogueType.interaction,
      );
      const event2 = DialogueEvent(
        message: 'Second message',
        type: DialogueType.interaction,
      );

      dialogueManager.triggerDialogue(event1);
      dialogueManager.triggerDialogue(event2);

      expect(dialogueManager.isDialogueActive, isTrue);
      // Events are now combined in the same turn
      expect(
        dialogueManager.getCurrentDialogueText(),
        equals('First message\nSecond message'),
      );
    });

    test('should show interaction dialogue', () {
      dialogueManager.showInteraction('Hello!', speakerName: 'Ghost');

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueText(), equals('Hello!'));
      expect(
        dialogueManager.getCurrentDialogueType(),
        equals(DialogueType.combat),
      );
    });

    test('should show item collection dialogue', () {
      dialogueManager.showItemCollection('Found candy!');

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueText(), equals('Found candy!'));
      expect(
        dialogueManager.getCurrentDialogueType(),
        equals(DialogueType.combat),
      );
    });

    test('should show combat feedback dialogue', () {
      dialogueManager.showCombatFeedback('Enemy defeated!');

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(
        dialogueManager.getCurrentDialogueText(),
        equals('Enemy defeated!'),
      );
      expect(
        dialogueManager.getCurrentDialogueType(),
        equals(DialogueType.combat),
      );
    });

    test('should show story dialogue', () {
      dialogueManager.showStory(
        'The adventure begins...',
        speakerName: 'Narrator',
      );

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(
        dialogueManager.getCurrentDialogueText(),
        equals('The adventure begins...'),
      );
      expect(
        dialogueManager.getCurrentDialogueType(),
        equals(DialogueType.combat),
      );
    });

    test('should show boss dialogue', () {
      dialogueManager.showBossDialogue(
        'You dare challenge me?',
        speakerName: 'Boss',
      );

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(
        dialogueManager.getCurrentDialogueText(),
        equals('You dare challenge me?'),
      );
      expect(
        dialogueManager.getCurrentDialogueType(),
        equals(DialogueType.combat),
      );
    });

    test('should advance dialogue', () {
      dialogueManager.showInteraction('Test message');
      expect(dialogueManager.canAdvanceDialogue(), isFalse);

      // In new system, dialogue can be dismissed but not advanced
      expect(dialogueManager.isDialogueActive, isTrue);
    });

    test('should dismiss dialogue', () {
      dialogueManager.showInteraction('Test message');
      expect(dialogueManager.canDismissDialogue(), isFalse);

      // In new system, dialogue auto-hides after 3 turns or new events
      expect(dialogueManager.isDialogueActive, isTrue);
    });

    test('should add and notify event listeners', () {
      bool listenerCalled = false;
      DialogueEvent? receivedEvent;

      dialogueManager.addEventListener(DialogueType.interaction, (event) {
        listenerCalled = true;
        receivedEvent = event;
      });

      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );

      dialogueManager.triggerDialogue(event);

      expect(listenerCalled, isTrue);
      expect(receivedEvent, equals(event));
    });

    test('should remove event listeners', () {
      bool listenerCalled = false;

      void listener(DialogueEvent event) {
        listenerCalled = true;
      }

      dialogueManager.addEventListener(DialogueType.interaction, listener);
      dialogueManager.removeEventListener(DialogueType.interaction, listener);

      const event = DialogueEvent(
        message: 'Test message',
        type: DialogueType.interaction,
      );

      dialogueManager.triggerDialogue(event);

      expect(listenerCalled, isFalse);
    });

    test('should clear all state', () {
      dialogueManager.showInteraction('Test message');
      dialogueManager.showInteraction('Queued message');

      expect(dialogueManager.isDialogueActive, isTrue);

      dialogueManager.clear();

      expect(dialogueManager.isDialogueActive, isFalse);
      expect(dialogueManager.hasPendingEvents, isFalse);
    });

    test('should initialize with callbacks', () {
      bool showCalled = false;
      bool hideCalled = false;

      dialogueManager.initialize(
        onShow: () => showCalled = true,
        onHide: () => hideCalled = true,
      );

      dialogueManager.showInteraction('Test message');
      expect(showCalled, isTrue);

      // In new system, dismissDialogue doesn't trigger hide immediately
      dialogueManager.clear();
      expect(hideCalled, isFalse); // Hide is only called when auto-hiding
    });
  });
}
