import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/dialogue_manager.dart';
import '../../lib/core/dialogue_event.dart';

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
      expect(dialogueManager.dialogueWindow.currentEvent, equals(event));
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
      expect(dialogueManager.hasPendingEvents, isTrue);
      expect(dialogueManager.dialogueWindow.currentEvent, equals(event1));
    });

    test('should show interaction dialogue', () {
      dialogueManager.showInteraction('Hello!', speakerName: 'Ghost');

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueText(), equals('Ghost: Hello!'));
      expect(dialogueManager.getCurrentDialogueType(), equals(DialogueType.interaction));
    });

    test('should show item collection dialogue', () {
      dialogueManager.showItemCollection('Found candy!');

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueText(), equals('Found candy!'));
      expect(dialogueManager.getCurrentDialogueType(), equals(DialogueType.itemCollection));
    });

    test('should show combat feedback dialogue', () {
      dialogueManager.showCombatFeedback('Enemy defeated!');

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueText(), equals('Enemy defeated!'));
      expect(dialogueManager.getCurrentDialogueType(), equals(DialogueType.combat));
    });

    test('should show story dialogue', () {
      dialogueManager.showStory('The adventure begins...', speakerName: 'Narrator');

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueText(), equals('Narrator: The adventure begins...'));
      expect(dialogueManager.getCurrentDialogueType(), equals(DialogueType.story));
    });

    test('should show boss dialogue', () {
      dialogueManager.showBossDialogue('You dare challenge me?', speakerName: 'Boss');

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueText(), equals('Boss: You dare challenge me?'));
      expect(dialogueManager.getCurrentDialogueType(), equals(DialogueType.boss));
    });

    test('should advance dialogue', () {
      dialogueManager.showInteraction('Test message');
      expect(dialogueManager.canAdvanceDialogue(), isTrue);

      dialogueManager.advanceDialogue();
      expect(dialogueManager.isDialogueActive, isFalse);
    });

    test('should dismiss dialogue', () {
      dialogueManager.showInteraction('Test message');
      expect(dialogueManager.canDismissDialogue(), isTrue);

      dialogueManager.dismissDialogue();
      expect(dialogueManager.isDialogueActive, isFalse);
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
      expect(dialogueManager.hasPendingEvents, isTrue);

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

      dialogueManager.dismissDialogue();
      expect(hideCalled, isTrue);
    });
  });
}