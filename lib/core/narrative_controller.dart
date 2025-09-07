import 'dialogue_manager.dart';

/// Manages story progression and contextual dialogue throughout the game
class NarrativeController {
  final DialogueManager _dialogueManager;
  final Map<String, bool> _storyFlags = {};
  final Map<String, int> _eventCounters = {};

  NarrativeController(this._dialogueManager);

  /// Gets the dialogue manager instance
  DialogueManager get dialogueManager => _dialogueManager;

  /// Sets a story flag to track game progress
  void setStoryFlag(String flag, bool value) {
    _storyFlags[flag] = value;
  }

  /// Gets a story flag value
  bool getStoryFlag(String flag) {
    return _storyFlags[flag] ?? false;
  }

  /// Increments an event counter
  void incrementEventCounter(String event) {
    _eventCounters[event] = (_eventCounters[event] ?? 0) + 1;
  }

  /// Gets an event counter value
  int getEventCounter(String event) {
    return _eventCounters[event] ?? 0;
  }

  /// Triggers dialogue for game start
  void triggerGameStart() {
    if (!getStoryFlag('game_started')) {
      _dialogueManager.showStory(
        'Welcome to the haunted realm, Kiro! Navigate through the mysterious world, collect candy, and make allies on your journey to face the final boss.',
        speakerName: 'Narrator',
      );
      setStoryFlag('game_started', true);
    }
  }

  /// Triggers dialogue for first enemy encounter
  void triggerFirstEnemyEncounter() {
    if (!getStoryFlag('first_enemy_encountered')) {
      _dialogueManager.showStory(
        'A hostile creature blocks your path! You can try to befriend it by offering candy, or find another way around.',
        speakerName: 'Narrator',
      );
      setStoryFlag('first_enemy_encountered', true);
    }
  }

  /// Triggers dialogue for first candy collection
  void triggerFirstCandyCollection(String candyName) {
    if (!getStoryFlag('first_candy_collected')) {
      _dialogueManager.showStory(
        'Excellent! You found your first candy: $candyName. Candy can be used to befriend enemies or enhance your abilities.',
        speakerName: 'Narrator',
      );
      setStoryFlag('first_candy_collected', true);
    }
  }

  /// Triggers dialogue for first ally conversion
  void triggerFirstAllyConversion() {
    if (!getStoryFlag('first_ally_made')) {
      _dialogueManager.showStory(
        'Wonderful! You\'ve made your first ally. Allied creatures will follow you and help fight hostile enemies.',
        speakerName: 'Narrator',
      );
      setStoryFlag('first_ally_made', true);
    }
  }

  /// Triggers dialogue for first combat
  void triggerFirstCombat() {
    if (!getStoryFlag('first_combat_seen')) {
      _dialogueManager.showStory(
        'Your ally is engaging in combat! Watch as they fight to protect you from hostile creatures.',
        speakerName: 'Narrator',
      );
      setStoryFlag('first_combat_seen', true);
    }
  }

  /// Triggers dialogue for boss area approach
  void triggerBossAreaApproach() {
    if (!getStoryFlag('boss_area_approached')) {
      _dialogueManager.showStory(
        'You sense a powerful presence ahead. The final boss awaits! Make sure you\'re prepared with allies and candy.',
        speakerName: 'Narrator',
      );
      setStoryFlag('boss_area_approached', true);
    }
  }

  /// Triggers dialogue for boss encounter
  void triggerBossEncounter() {
    _dialogueManager.showBossDialogue(
      'So, you\'ve made it this far, little ghost. But your journey ends here!',
      speakerName: 'Boss Monster',
    );
  }

  /// Triggers dialogue for boss defeat
  void triggerBossDefeat() {
    _dialogueManager.showBossDialogue(
      'Impossible... How could a mere ghost defeat me?',
      speakerName: 'Boss Monster',
    );

    // Follow up with victory message
    Future.delayed(const Duration(seconds: 2), () {
      _dialogueManager.showStory(
        'Congratulations, Kiro! You have defeated the boss and brought peace to the haunted realm. Your courage and kindness have saved the day!',
        speakerName: 'Narrator',
      );
      setStoryFlag('game_completed', true);
    });
  }

  /// Triggers contextual dialogue based on game state
  void triggerContextualDialogue() {
    final candyCount = getEventCounter('candy_collected');
    final allyCount = getEventCounter('allies_made');
    final combatCount = getEventCounter('combats_witnessed');

    // Milestone dialogues
    if (candyCount == 5 && !getStoryFlag('candy_milestone_5')) {
      _dialogueManager.showStory(
        'You\'re becoming quite the candy collector! Each type of candy offers unique benefits.',
        speakerName: 'Narrator',
      );
      setStoryFlag('candy_milestone_5', true);
    }

    if (allyCount == 3 && !getStoryFlag('ally_milestone_3')) {
      _dialogueManager.showStory(
        'You\'re building quite the team! Your allies will be invaluable in the challenges ahead.',
        speakerName: 'Narrator',
      );
      setStoryFlag('ally_milestone_3', true);
    }

    if (combatCount == 10 && !getStoryFlag('combat_milestone_10')) {
      _dialogueManager.showStory(
        'Your allies have proven themselves in many battles. They\'re becoming stronger and more loyal.',
        speakerName: 'Narrator',
      );
      setStoryFlag('combat_milestone_10', true);
    }
  }

  /// Resets all story progress
  void resetStory() {
    _storyFlags.clear();
    _eventCounters.clear();
  }

  /// Gets current story progress as a map
  Map<String, dynamic> getStoryProgress() {
    return {
      'flags': Map<String, bool>.from(_storyFlags),
      'counters': Map<String, int>.from(_eventCounters),
    };
  }

  /// Loads story progress from a map
  void loadStoryProgress(Map<String, dynamic> progress) {
    if (progress['flags'] is Map) {
      _storyFlags.clear();
      _storyFlags.addAll(Map<String, bool>.from(progress['flags']));
    }

    if (progress['counters'] is Map) {
      _eventCounters.clear();
      _eventCounters.addAll(Map<String, int>.from(progress['counters']));
    }
  }
}
