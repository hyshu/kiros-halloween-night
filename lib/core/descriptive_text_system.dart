import 'dialogue_manager.dart';
import 'position.dart';

/// System for generating descriptive text for game events and story moments
class DescriptiveTextSystem {
  final DialogueManager _dialogueManager;

  DescriptiveTextSystem(this._dialogueManager);

  /// Gets the dialogue manager instance
  DialogueManager get dialogueManager => _dialogueManager;

  /// Describes the current environment based on position
  void describeEnvironment(Position position, {
    bool hasEnemies = false,
    bool hasCandy = false,
    bool hasAllies = false,
    String? specialFeature,
  }) {
    final description = _generateEnvironmentDescription(
      position,
      hasEnemies: hasEnemies,
      hasCandy: hasCandy,
      hasAllies: hasAllies,
      specialFeature: specialFeature,
    );

    if (description.isNotEmpty) {
      _dialogueManager.showStory(description, speakerName: 'Narrator');
    }
  }

  /// Describes movement and exploration
  void describeMovement(Position from, Position to, {
    String? obstacleEncountered,
    String? discoveredItem,
  }) {
    if (obstacleEncountered != null) {
      _dialogueManager.showStory(
        'Your path is blocked by $obstacleEncountered.',
        speakerName: 'Narrator',
      );
      return;
    }

    if (discoveredItem != null) {
      _dialogueManager.showStory(
        'As you move, you notice $discoveredItem nearby.',
        speakerName: 'Narrator',
      );
    }

    // Occasional atmospheric descriptions during movement
    if (_shouldShowMovementDescription(from, to)) {
      final description = _generateMovementDescription(from, to);
      _dialogueManager.showStory(description, speakerName: 'Narrator');
    }
  }

  /// Describes game state changes
  void describeStateChange(String changeType, {
    Map<String, dynamic>? context,
  }) {
    String description;

    switch (changeType) {
      case 'health_low':
        description = 'You feel weakened. Perhaps some candy could restore your strength.';
        break;
      case 'inventory_full':
        description = 'Your pockets are full of candy. Consider using some to make allies.';
        break;
      case 'no_allies':
        description = 'You journey alone through the haunted realm. Allies could provide valuable assistance.';
        break;
      case 'many_allies':
        final count = context?['ally_count'] ?? 0;
        description = 'You are accompanied by $count loyal allies. Their presence gives you confidence.';
        break;
      case 'area_cleared':
        description = 'This area seems peaceful now. The hostile presence has lifted.';
        break;
      case 'danger_nearby':
        description = 'You sense danger lurking in the shadows. Proceed with caution.';
        break;
      case 'safe_area':
        description = 'This area feels safe and welcoming. A good place to rest and plan your next move.';
        break;
      default:
        return; // No description for unknown state changes
    }

    _dialogueManager.showStory(description, speakerName: 'Narrator');
  }

  /// Describes special events and discoveries
  void describeSpecialEvent(String eventType, {
    Map<String, dynamic>? context,
  }) {
    String description;

    switch (eventType) {
      case 'secret_area_found':
        final areaName = context?['area_name'] ?? 'a hidden chamber';
        description = 'You have discovered $areaName! This secret area may contain valuable treasures.';
        break;
      case 'rare_candy_found':
        final candyName = context?['candy_name'] ?? 'a rare candy';
        description = 'Incredible! You have found $candyName, a legendary confection with powerful properties.';
        break;
      case 'ancient_relic':
        final relicName = context?['relic_name'] ?? 'an ancient artifact';
        description = 'You sense the presence of $relicName. Its power resonates through the realm.';
        break;
      case 'ghostly_whispers':
        description = 'Ethereal whispers echo through the air, speaking of ancient secrets and forgotten lore.';
        break;
      case 'magical_aura':
        description = 'A magical aura permeates this area, making the very air shimmer with otherworldly energy.';
        break;
      case 'time_distortion':
        description = 'Time seems to flow differently here. Past and present blur together in mysterious ways.';
        break;
      default:
        return; // No description for unknown events
    }

    _dialogueManager.showStory(description, speakerName: 'Narrator');
  }

  /// Describes emotional moments and character development
  void describeEmotionalMoment(String momentType, {
    Map<String, dynamic>? context,
  }) {
    String description;

    switch (momentType) {
      case 'first_friend':
        description = 'A warm feeling fills your ghostly heart. You are no longer alone in this realm.';
        break;
      case 'ally_sacrifice':
        final allyName = context?['ally_name'] ?? 'your ally';
        description = '$allyName\'s sacrifice will not be forgotten. Their loyalty has touched your soul.';
        break;
      case 'redemption':
        description = 'Through kindness and compassion, you have brought light to the darkness.';
        break;
      case 'courage_found':
        description = 'You feel a surge of courage. The challenges ahead no longer seem insurmountable.';
        break;
      case 'wisdom_gained':
        description = 'Your experiences have taught you valuable lessons about friendship and perseverance.';
        break;
      case 'hope_restored':
        description = 'Hope blooms in your heart like a flower in the darkness. The future looks brighter.';
        break;
      default:
        return; // No description for unknown moments
    }

    _dialogueManager.showStory(description, speakerName: 'Narrator');
  }

  // Helper methods for generating contextual descriptions

  String _generateEnvironmentDescription(
    Position position, {
    required bool hasEnemies,
    required bool hasCandy,
    required bool hasAllies,
    String? specialFeature,
  }) {
    final descriptions = <String>[];

    // Base environment description
    if (position.x < 50 && position.z < 100) {
      descriptions.add('You find yourself in the entrance halls of the haunted realm.');
    } else if (position.x > 150 && position.z > 300) {
      descriptions.add('You approach the deeper, more dangerous regions of the realm.');
    } else {
      descriptions.add('You traverse the mysterious corridors of the haunted realm.');
    }

    // Add contextual elements
    if (hasEnemies && hasCandy) {
      descriptions.add('Hostile entities guard valuable candy in this area.');
    } else if (hasEnemies) {
      descriptions.add('Dangerous creatures lurk in the shadows here.');
    } else if (hasCandy) {
      descriptions.add('Sweet treasures await discovery in this peaceful area.');
    }

    if (hasAllies) {
      descriptions.add('Your loyal allies stand ready to assist you.');
    }

    if (specialFeature != null) {
      descriptions.add(specialFeature);
    }

    return descriptions.join(' ');
  }

  String _generateMovementDescription(Position from, Position to) {
    final atmosphericDescriptions = [
      'The ancient stones echo with your footsteps.',
      'Shadows dance on the walls as you pass.',
      'A cool breeze carries whispers from distant chambers.',
      'The air grows thicker as you venture deeper.',
      'Mysterious symbols glow faintly on the walls.',
      'You feel the weight of countless years in this place.',
      'The realm seems to shift and change around you.',
      'Ethereal lights guide your path forward.',
    ];

    // Use position to deterministically select description
    final index = (from.x + from.z + to.x + to.z) % atmosphericDescriptions.length;
    return atmosphericDescriptions[index];
  }

  bool _shouldShowMovementDescription(Position from, Position to) {
    // Show atmospheric descriptions occasionally (roughly 10% of moves)
    return (from.x + from.z + to.x + to.z) % 10 == 0;
  }
}