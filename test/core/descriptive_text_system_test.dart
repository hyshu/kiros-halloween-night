import 'package:flutter_test/flutter_test.dart';
import 'package:kiro_halloween_game/core/descriptive_text_system.dart';
import 'package:kiro_halloween_game/core/dialogue_manager.dart';
import 'package:kiro_halloween_game/core/dialogue_event.dart';
import 'package:kiro_halloween_game/core/position.dart';

void main() {
  group('DescriptiveTextSystem', () {
    late DescriptiveTextSystem descriptiveSystem;
    late DialogueManager dialogueManager;

    setUp(() {
      dialogueManager = DialogueManager();
      descriptiveSystem = DescriptiveTextSystem(dialogueManager);
    });

    test('should describe environment with contextual elements', () {
      const position = Position(25, 50);

      descriptiveSystem.describeEnvironment(
        position,
        hasEnemies: true,
        hasCandy: true,
        hasAllies: false,
      );

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(
        dialogueManager.getCurrentDialogueType(),
        equals(DialogueType.combat),
      );
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('entrance halls'),
      );
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('guard valuable candy'),
      );
    });

    test('should describe different areas based on position', () {
      // Test entrance area
      const entrancePosition = Position(25, 50);
      descriptiveSystem.describeEnvironment(entrancePosition);
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('entrance halls'),
      );

      dialogueManager.clear();

      // Test deeper area
      const deepPosition = Position(175, 350);
      descriptiveSystem.describeEnvironment(deepPosition);
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('deeper, more dangerous'),
      );

      dialogueManager.clear();

      // Test middle area
      const middlePosition = Position(100, 200);
      descriptiveSystem.describeEnvironment(middlePosition);
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('mysterious corridors'),
      );
    });

    test('should describe movement with obstacles', () {
      const from = Position(10, 10);
      const to = Position(11, 10);

      descriptiveSystem.describeMovement(
        from,
        to,
        obstacleEncountered: 'a massive stone wall',
      );

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('blocked by a massive stone wall'),
      );
    });

    test('should describe movement with discoveries', () {
      const from = Position(5, 5);
      const to = Position(6, 5);

      descriptiveSystem.describeMovement(
        from,
        to,
        discoveredItem: 'a glowing crystal',
      );

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('glowing crystal nearby'),
      );
    });

    test('should describe state changes', () {
      descriptiveSystem.describeStateChange('health_low');
      expect(dialogueManager.isDialogueActive, isTrue);
      expect(dialogueManager.getCurrentDialogueText(), contains('weakened'));

      dialogueManager.clear();

      descriptiveSystem.describeStateChange(
        'many_allies',
        context: {'ally_count': 3},
      );
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('3 loyal allies'),
      );
    });

    test('should describe special events', () {
      descriptiveSystem.describeSpecialEvent(
        'secret_area_found',
        context: {'area_name': 'the Crystal Cavern'},
      );

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('Crystal Cavern'),
      );
      expect(dialogueManager.getCurrentDialogueText(), contains('secret area'));
    });

    test('should describe emotional moments', () {
      descriptiveSystem.describeEmotionalMoment('first_friend');
      expect(dialogueManager.isDialogueActive, isTrue);
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('warm feeling'),
      );
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('no longer alone'),
      );

      dialogueManager.clear();

      descriptiveSystem.describeEmotionalMoment(
        'ally_sacrifice',
        context: {'ally_name': 'Brave Guardian'},
      );
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('Brave Guardian'),
      );
      expect(dialogueManager.getCurrentDialogueText(), contains('sacrifice'));
    });

    test('should handle unknown event types gracefully', () {
      descriptiveSystem.describeStateChange('unknown_state');
      expect(dialogueManager.isDialogueActive, isFalse);

      descriptiveSystem.describeSpecialEvent('unknown_event');
      expect(dialogueManager.isDialogueActive, isFalse);

      descriptiveSystem.describeEmotionalMoment('unknown_moment');
      expect(dialogueManager.isDialogueActive, isFalse);
    });

    test('should provide atmospheric movement descriptions occasionally', () {
      // Test specific movement that should trigger atmospheric description
      // Using positions that sum to a multiple of 10
      const from = Position(0, 0);
      const to = Position(5, 5);

      descriptiveSystem.describeMovement(from, to);

      expect(dialogueManager.isDialogueActive, isTrue);
      final text = dialogueManager.getCurrentDialogueText();
      expect(
        text.contains('echo') ||
            text.contains('shadows') ||
            text.contains('whispers') ||
            text.contains('stones') ||
            text.contains('breeze') ||
            text.contains('symbols'),
        isTrue,
      );
    });

    test('should describe environment with special features', () {
      const position = Position(50, 100);

      descriptiveSystem.describeEnvironment(
        position,
        specialFeature: 'An ancient altar stands in the center of the room.',
      );

      expect(dialogueManager.isDialogueActive, isTrue);
      expect(
        dialogueManager.getCurrentDialogueText(),
        contains('ancient altar'),
      );
    });
  });
}
