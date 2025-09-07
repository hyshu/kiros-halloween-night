import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/narrative_controller.dart';
import '../../lib/core/dialogue_manager.dart';
import '../../lib/core/dialogue_event.dart';

void main() {
  group('NarrativeController', () {
    late NarrativeController narrativeController;
    late DialogueManager dialogueManager;

    setUp(() {
      dialogueManager = DialogueManager();
      narrativeController = NarrativeController(dialogueManager);
    });

    test('should initialize with empty state', () {
      expect(narrativeController.getStoryFlag('any_flag'), isFalse);
      expect(narrativeController.getEventCounter('any_event'), equals(0));
    });

    test('should set and get story flags', () {
      narrativeController.setStoryFlag('test_flag', true);
      expect(narrativeController.getStoryFlag('test_flag'), isTrue);

      narrativeController.setStoryFlag('test_flag', false);
      expect(narrativeController.getStoryFlag('test_flag'), isFalse);
    });

    test('should increment and get event counters', () {
      expect(narrativeController.getEventCounter('test_event'), equals(0));

      narrativeController.incrementEventCounter('test_event');
      expect(narrativeController.getEventCounter('test_event'), equals(1));

      narrativeController.incrementEventCounter('test_event');
      expect(narrativeController.getEventCounter('test_event'), equals(2));
    });

    test('should trigger game start dialogue once', () {
      narrativeController.triggerGameStart();
      expect(narrativeController.getStoryFlag('game_started'), isTrue);
      expect(dialogueManager.isDialogueActive, isTrue);

      // Clear dialogue and try again
      dialogueManager.clear();
      narrativeController.triggerGameStart();
      expect(dialogueManager.isDialogueActive, isFalse); // Should not trigger again
    });

    test('should trigger first enemy encounter dialogue once', () {
      narrativeController.triggerFirstEnemyEncounter();
      expect(narrativeController.getStoryFlag('first_enemy_encountered'), isTrue);
      expect(dialogueManager.isDialogueActive, isTrue);

      // Clear dialogue and try again
      dialogueManager.clear();
      narrativeController.triggerFirstEnemyEncounter();
      expect(dialogueManager.isDialogueActive, isFalse); // Should not trigger again
    });

    test('should trigger first candy collection dialogue once', () {
      narrativeController.triggerFirstCandyCollection('Chocolate');
      expect(narrativeController.getStoryFlag('first_candy_collected'), isTrue);
      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueText(), contains('Chocolate'));
    });

    test('should trigger first ally conversion dialogue once', () {
      narrativeController.triggerFirstAllyConversion();
      expect(narrativeController.getStoryFlag('first_ally_made'), isTrue);
      expect(dialogueManager.isDialogueActive, isTrue);
    });

    test('should trigger first combat dialogue once', () {
      narrativeController.triggerFirstCombat();
      expect(narrativeController.getStoryFlag('first_combat_seen'), isTrue);
      expect(dialogueManager.isDialogueActive, isTrue);
    });

    test('should trigger boss area approach dialogue once', () {
      narrativeController.triggerBossAreaApproach();
      expect(narrativeController.getStoryFlag('boss_area_approached'), isTrue);
      expect(dialogueManager.isDialogueActive, isTrue);
    });

    test('should trigger boss encounter dialogue', () {
      narrativeController.triggerBossEncounter();
      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueType(), equals(DialogueType.boss));
    });

    test('should trigger contextual dialogue based on milestones', () {
      // Set up counters for milestones
      for (int i = 0; i < 5; i++) {
        narrativeController.incrementEventCounter('candy_collected');
      }

      narrativeController.triggerContextualDialogue();
      expect(narrativeController.getStoryFlag('candy_milestone_5'), isTrue);
      expect(dialogueManager.isDialogueActive, isTrue);
    });

    test('should save and load story progress', () {
      narrativeController.setStoryFlag('test_flag', true);
      narrativeController.incrementEventCounter('test_event');
      narrativeController.incrementEventCounter('test_event');

      final progress = narrativeController.getStoryProgress();
      expect(progress['flags']['test_flag'], isTrue);
      expect(progress['counters']['test_event'], equals(2));

      // Create new controller and load progress
      final newController = NarrativeController(DialogueManager());
      newController.loadStoryProgress(progress);

      expect(newController.getStoryFlag('test_flag'), isTrue);
      expect(newController.getEventCounter('test_event'), equals(2));
    });

    test('should reset story progress', () {
      narrativeController.setStoryFlag('test_flag', true);
      narrativeController.incrementEventCounter('test_event');

      narrativeController.resetStory();

      expect(narrativeController.getStoryFlag('test_flag'), isFalse);
      expect(narrativeController.getEventCounter('test_event'), equals(0));
    });
  });
}