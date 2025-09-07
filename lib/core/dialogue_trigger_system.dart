import 'dialogue_manager.dart';
import 'narrative_controller.dart';
import 'candy_item.dart';
import 'enemy_character.dart';
import 'ally_character.dart';

/// System for triggering dialogue events based on game interactions
class DialogueTriggerSystem {
  final DialogueManager _dialogueManager;
  final NarrativeController _narrativeController;

  DialogueTriggerSystem(this._dialogueManager, this._narrativeController);

  /// Gets the dialogue manager instance
  DialogueManager get dialogueManager => _dialogueManager;

  /// Gets the narrative controller instance
  NarrativeController get narrativeController => _narrativeController;

  /// Triggers dialogue for enemy interactions
  void triggerEnemyInteraction(EnemyCharacter enemy, {String? action}) {
    // First enemy encounter tutorial
    _narrativeController.triggerFirstEnemyEncounter();

    // Contextual dialogue based on enemy type and action
    switch (action) {
      case 'approach':
        _dialogueManager.showInteraction(
          _getEnemyApproachDialogue(enemy),
          speakerName: _getEnemyName(enemy),
        );
        break;
      case 'gift_offered':
        _dialogueManager.showInteraction(
          _getEnemyGiftResponseDialogue(enemy),
          speakerName: _getEnemyName(enemy),
        );
        break;
      case 'conversion':
        _dialogueManager.showInteraction(
          _getEnemyConversionDialogue(enemy),
          speakerName: _getEnemyName(enemy),
        );
        _narrativeController.triggerFirstAllyConversion();
        _narrativeController.incrementEventCounter('allies_made');
        break;
      case 'hostile':
        _dialogueManager.showInteraction(
          _getEnemyHostileDialogue(enemy),
          speakerName: _getEnemyName(enemy),
        );
        break;
      default:
        _dialogueManager.showInteraction(
          _getEnemyDefaultDialogue(enemy),
          speakerName: _getEnemyName(enemy),
        );
    }
  }

  /// Triggers dialogue for item collection
  void triggerItemCollection(CandyItem candy) {
    // First candy collection tutorial
    _narrativeController.triggerFirstCandyCollection(candy.name);

    // Collection feedback
    _dialogueManager.showItemCollection(_getCandyCollectionDialogue(candy));

    // Update counters and check for contextual dialogue
    _narrativeController.incrementEventCounter('candy_collected');
    _narrativeController.triggerContextualDialogue();
  }

  /// Triggers dialogue for combat events
  void triggerCombatEvent(
    String eventType, {
    AllyCharacter? ally,
    EnemyCharacter? enemy,
    String? outcome,
  }) {
    // First combat tutorial
    _narrativeController.triggerFirstCombat();

    switch (eventType) {
      case 'combat_start':
        _dialogueManager.showCombatFeedback(
          _getCombatStartDialogue(ally, enemy),
        );
        break;
      case 'combat_end':
        _dialogueManager.showCombatFeedback(
          _getCombatEndDialogue(ally, enemy, outcome),
        );
        break;
      case 'ally_defeated':
        _dialogueManager.showCombatFeedback(_getAllyDefeatedDialogue(ally));
        break;
      case 'enemy_defeated':
        _dialogueManager.showCombatFeedback(_getEnemyDefeatedDialogue(enemy));
        break;
    }

    // Update counters and check for contextual dialogue
    _narrativeController.incrementEventCounter('combats_witnessed');
    _narrativeController.triggerContextualDialogue();
  }

  /// Triggers dialogue for story events
  void triggerStoryEvent(String eventType, {Map<String, dynamic>? context}) {
    switch (eventType) {
      case 'game_start':
        _narrativeController.triggerGameStart();
        break;
      case 'boss_area_approach':
        _narrativeController.triggerBossAreaApproach();
        break;
      case 'boss_encounter':
        _narrativeController.triggerBossEncounter();
        break;
      case 'boss_defeat':
        _narrativeController.triggerBossDefeat();
        break;
      case 'area_discovered':
        final areaName = context?['area_name'] ?? 'Unknown Area';
        _dialogueManager.showStory(
          'You have discovered: $areaName',
          speakerName: 'Narrator',
        );
        break;
      case 'milestone_reached':
        final milestone = context?['milestone'] ?? 'Unknown Milestone';
        _dialogueManager.showStory(
          'Milestone reached: $milestone',
          speakerName: 'Narrator',
        );
        break;
    }
  }

  // Helper methods for generating contextual dialogue

  String _getEnemyName(EnemyCharacter enemy) {
    // Generate name based on enemy model or type
    if (enemy.modelPath.contains('character-male')) {
      return 'Wandering Spirit';
    } else if (enemy.modelPath.contains('character-female')) {
      return 'Lost Soul';
    } else if (enemy.modelPath.contains('monster')) {
      return 'Shadow Beast';
    }
    return 'Mysterious Entity';
  }

  String _getEnemyApproachDialogue(EnemyCharacter enemy) {
    final dialogues = [
      'Who dares approach me?',
      'Stay back, ghost!',
      'What do you want from me?',
      'I sense no malice in you... curious.',
      'Another wanderer in this cursed realm?',
    ];
    return dialogues[enemy.position.x % dialogues.length];
  }

  String _getEnemyGiftResponseDialogue(EnemyCharacter enemy) {
    final dialogues = [
      'A gift? For me? How... unexpected.',
      'Is this some kind of trick?',
      'I haven\'t received kindness in so long...',
      'This candy... it reminds me of better times.',
      'Your generosity touches my heart.',
    ];
    return dialogues[enemy.position.z % dialogues.length];
  }

  String _getEnemyConversionDialogue(EnemyCharacter enemy) {
    final dialogues = [
      'Your kindness has awakened something in me. I will follow you!',
      'I remember now... I was once good. Thank you for reminding me.',
      'This sweetness has melted my cold heart. I am yours to command!',
      'You have shown me mercy. I pledge my loyalty to you.',
      'The darkness lifts from my soul. I will fight beside you!',
    ];
    return dialogues[(enemy.position.x + enemy.position.z) % dialogues.length];
  }

  String _getEnemyHostileDialogue(EnemyCharacter enemy) {
    final dialogues = [
      'You will not pass!',
      'This realm belongs to the darkness!',
      'Begone, spirit!',
      'I will not be swayed by your tricks!',
      'Face my wrath!',
    ];
    return dialogues[enemy.health % dialogues.length];
  }

  String _getEnemyDefaultDialogue(EnemyCharacter enemy) {
    final dialogues = [
      'I wander these halls endlessly...',
      'The shadows whisper strange things.',
      'Have you seen the others like us?',
      'This place holds many secrets.',
      'Be careful, ghost. Danger lurks everywhere.',
    ];
    return dialogues[enemy.position.x % dialogues.length];
  }

  String _getCandyCollectionDialogue(CandyItem candy) {
    return 'Found ${candy.name}! ${_getCandyEffectDescription(candy)}';
  }

  String _getCandyEffectDescription(CandyItem candy) {
    switch (candy.effect) {
      case CandyEffect.healthBoost:
        return 'This will restore your vitality.';
      case CandyEffect.speedIncrease:
        return 'This will make you move faster.';
      case CandyEffect.allyStrength:
        return 'This will strengthen your allies.';
      case CandyEffect.specialAbility:
        return 'This grants a special power.';
      case CandyEffect.statModification:
        return 'This will enhance your abilities.';
      case CandyEffect.maxHealthIncrease:
        return 'This will increase your maximum health.';
    }
  }

  String _getCombatStartDialogue(AllyCharacter? ally, EnemyCharacter? enemy) {
    final allyName = ally != null ? _getAllyName(ally) : 'Your ally';
    final enemyName = enemy != null ? _getEnemyName(enemy) : 'the enemy';
    return '$allyName engages $enemyName in combat!';
  }

  String _getCombatEndDialogue(
    AllyCharacter? ally,
    EnemyCharacter? enemy,
    String? outcome,
  ) {
    switch (outcome) {
      case 'ally_victory':
        return 'Your ally emerges victorious!';
      case 'enemy_victory':
        return 'The enemy has defeated your ally.';
      case 'draw':
        return 'The battle ends in a stalemate.';
      default:
        return 'The combat has concluded.';
    }
  }

  String _getAllyDefeatedDialogue(AllyCharacter? ally) {
    final allyName = ally != null ? _getAllyName(ally) : 'Your ally';
    return '$allyName has been defeated but feels satisfied with their service.';
  }

  String _getEnemyDefeatedDialogue(EnemyCharacter? enemy) {
    final enemyName = enemy != null ? _getEnemyName(enemy) : 'The enemy';
    return '$enemyName has been defeated!';
  }

  String _getAllyName(AllyCharacter ally) {
    // Generate name based on ally's original enemy type
    if (ally.modelPath.contains('character-male')) {
      return 'Loyal Guardian';
    } else if (ally.modelPath.contains('character-female')) {
      return 'Faithful Companion';
    } else if (ally.modelPath.contains('monster')) {
      return 'Reformed Beast';
    }
    return 'Trusted Ally';
  }
}
