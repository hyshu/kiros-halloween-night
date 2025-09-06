import 'package:flutter/foundation.dart';
import 'candy_item.dart';
import 'enemy_character.dart';
import 'ghost_character.dart';
import 'position.dart';
import 'enemy_spawner.dart';

/// Manages the gift system for giving candy to adjacent enemies
class GiftSystem extends ChangeNotifier {
  /// Currently selected candy for gifting
  CandyItem? _selectedCandy;
  
  /// Whether the gift UI is currently active
  bool _isGiftUIActive = false;
  
  /// Available candy items for gifting
  List<CandyItem> _availableCandy = [];
  
  /// Target enemy for gifting
  EnemyCharacter? _targetEnemy;

  /// Gets the currently selected candy
  CandyItem? get selectedCandy => _selectedCandy;
  
  /// Gets whether the gift UI is active
  bool get isGiftUIActive => _isGiftUIActive;
  
  /// Gets the available candy for gifting
  List<CandyItem> get availableCandy => List.unmodifiable(_availableCandy);
  
  /// Gets the target enemy
  EnemyCharacter? get targetEnemy => _targetEnemy;

  /// Initiates the gift process with an adjacent enemy
  /// Returns true if the gift UI was successfully opened
  bool initiateGift(GhostCharacter player, EnemyCharacter enemy) {
    // Check if enemy is adjacent
    if (!_isAdjacent(player.position, enemy.position)) {
      return false;
    }
    
    // Check if enemy can receive gifts (must be hostile)
    if (!enemy.isHostile) {
      return false;
    }
    
    // Get available candy for gifting
    _availableCandy = player.getAvailableCandyForGifting();
    
    // Check if player has any candy to give
    if (_availableCandy.isEmpty) {
      return false;
    }
    
    // Set up gift UI state
    _targetEnemy = enemy;
    _isGiftUIActive = true;
    _selectedCandy = null;
    
    notifyListeners();
    return true;
  }

  /// Selects a candy item for gifting
  void selectCandy(CandyItem candy) {
    if (!_availableCandy.contains(candy)) {
      return;
    }
    
    _selectedCandy = candy;
    notifyListeners();
  }

  /// Confirms the gift and performs the enemy-to-ally conversion
  /// Returns true if the gift was successful
  bool confirmGift(GhostCharacter player) {
    if (!_isGiftUIActive || _selectedCandy == null || _targetEnemy == null) {
      return false;
    }
    
    // Remove candy from player's inventory
    final giftedCandy = player.giveCandy(_selectedCandy!.id);
    if (giftedCandy == null) {
      return false;
    }
    
    // Convert enemy to ally
    _convertEnemyToAlly(_targetEnemy!, giftedCandy);
    
    // Close gift UI
    _closeGiftUI();
    
    return true;
  }

  /// Cancels the gift process
  void cancelGift() {
    _closeGiftUI();
  }

  /// Closes the gift UI and resets state
  void _closeGiftUI() {
    _isGiftUIActive = false;
    _selectedCandy = null;
    _targetEnemy = null;
    _availableCandy.clear();
    notifyListeners();
  }

  /// Converts an enemy to ally state and applies satisfaction behavior
  void _convertEnemyToAlly(EnemyCharacter enemy, CandyItem candy) {
    // Convert enemy state
    enemy.convertToAlly();
    
    // Apply candy effects to the enemy (satisfaction behavior)
    _applyCandyEffectsToEnemy(enemy, candy);
    
    // Trigger satisfaction display behavior
    _displaySatisfactionBehavior(enemy, candy);
  }

  /// Applies candy effects to the converted enemy
  void _applyCandyEffectsToEnemy(EnemyCharacter enemy, CandyItem candy) {
    switch (candy.effect) {
      case CandyEffect.healthBoost:
        // Heal the enemy
        enemy.heal(candy.value);
        break;
        
      case CandyEffect.maxHealthIncrease:
        // This would require modifying the Character class
        // For now, just heal to full
        enemy.heal(enemy.maxHealth);
        break;
        
      case CandyEffect.speedIncrease:
        // Reduce movement cooldown for faster movement
        enemy.movementCooldown = 0;
        break;
        
      case CandyEffect.allyStrength:
        // This will be used when combat system is implemented
        // For now, just heal the enemy
        enemy.heal(candy.value);
        break;
        
      case CandyEffect.specialAbility:
      case CandyEffect.statModification:
        // These effects could be stored on the enemy for future use
        // For now, just provide a small health boost
        enemy.heal(10);
        break;
    }
  }

  /// Displays satisfaction behavior when enemy becomes ally
  void _displaySatisfactionBehavior(EnemyCharacter enemy, CandyItem candy) {
    // This would integrate with the dialogue system when implemented
    // For now, we'll just mark the enemy as satisfied with the gift
    
    // The satisfaction behavior is shown through the state change
    // and will be visible in the game through the enemy's new behavior
    
    // In a full implementation, this would trigger:
    // - Visual effects (sparkles, hearts, etc.)
    // - Sound effects
    // - Dialogue text showing the enemy's satisfaction
    // - Animation changes to show friendly behavior
  }

  /// Checks if two positions are adjacent (within 1 tile)
  bool _isAdjacent(Position pos1, Position pos2) {
    final dx = (pos1.x - pos2.x).abs();
    final dz = (pos1.z - pos2.z).abs();
    
    // Adjacent means exactly 1 tile away in one direction
    return (dx == 1 && dz == 0) || (dx == 0 && dz == 1);
  }

  /// Gets all adjacent enemies to the player that can receive gifts
  List<EnemyCharacter> getAdjacentGiftableEnemies(
    GhostCharacter player, 
    List<EnemyCharacter> enemies
  ) {
    return enemies.where((enemy) {
      return _isAdjacent(player.position, enemy.position) && 
             enemy.isHostile && 
             enemy.isProximityActive;
    }).toList();
  }

  /// Checks if the player can give gifts (has candy and adjacent enemies)
  bool canGiveGifts(GhostCharacter player, List<EnemyCharacter> enemies) {
    if (player.inventory.isEmpty) return false;
    
    final giftableEnemies = getAdjacentGiftableEnemies(player, enemies);
    return giftableEnemies.isNotEmpty;
  }

  /// Gets the best candy recommendation for a specific enemy type
  CandyItem? getRecommendedCandy(EnemyCharacter enemy, List<CandyItem> availableCandy) {
    if (availableCandy.isEmpty) return null;
    
    // Recommend based on enemy type and current health
    switch (enemy.enemyType) {
      case EnemyType.human:
        // Humans prefer sweet treats
        final sweetCandy = availableCandy.where((candy) => 
          candy.effect == CandyEffect.healthBoost ||
          candy.name.toLowerCase().contains('chocolate') ||
          candy.name.toLowerCase().contains('cookie')
        ).toList();
        if (sweetCandy.isNotEmpty) return sweetCandy.first;
        break;
        
      case EnemyType.monster:
        // Monsters prefer powerful effects
        final powerfulCandy = availableCandy.where((candy) => 
          candy.effect == CandyEffect.specialAbility ||
          candy.effect == CandyEffect.allyStrength ||
          candy.value > 15
        ).toList();
        if (powerfulCandy.isNotEmpty) return powerfulCandy.first;
        break;
    }
    
    // Default to first available candy
    return availableCandy.first;
  }

  @override
  String toString() {
    return 'GiftSystem(active: $_isGiftUIActive, '
           'candy: ${_availableCandy.length}, '
           'selected: ${_selectedCandy?.name}, '
           'target: ${_targetEnemy?.id})';
  }
}

