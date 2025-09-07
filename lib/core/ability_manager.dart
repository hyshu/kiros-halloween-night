import 'package:flutter/foundation.dart';
import 'candy_item.dart';
import 'ghost_character.dart';

/// Manages the application and tracking of candy-based abilities and effects
class AbilityManager extends ChangeNotifier {
  /// The ghost character this manager is associated with
  final GhostCharacter character;

  /// Permanent stat modifications
  final Map<String, int> _permanentStats = {};

  /// Cached effective stats (recalculated when effects change)
  Map<String, dynamic>? _cachedStats;

  AbilityManager(this.character) {
    // Listen to inventory changes to update cached stats
    character.inventory.addListener(_onInventoryChanged);
  }

  /// Gets the permanent stat modifications
  Map<String, int> get permanentStats => Map.unmodifiable(_permanentStats);

  /// Applies a candy item's effects to the character
  void applyCandyEffect(CandyItem candy) {
    switch (candy.effect) {
      case CandyEffect.healthBoost:
        _applyHealthBoost(candy.value);
        break;

      case CandyEffect.maxHealthIncrease:
        _applyMaxHealthIncrease(candy.value);
        break;

      case CandyEffect.speedIncrease:
        _applyTemporaryEffect(candy);
        break;

      case CandyEffect.allyStrength:
        _applyTemporaryEffect(candy);
        break;

      case CandyEffect.specialAbility:
        _applySpecialAbility(candy);
        break;

      case CandyEffect.statModification:
        _applyStatModification(candy);
        break;
    }

    _invalidateCache();
    notifyListeners();
  }

  /// Applies a health boost effect
  void _applyHealthBoost(int amount) {
    character.heal(amount);
  }

  /// Applies a permanent max health increase
  void _applyMaxHealthIncrease(int amount) {
    _permanentStats['maxHealth'] = (_permanentStats['maxHealth'] ?? 0) + amount;

    // Also heal the character by the same amount
    character.heal(amount);
  }

  /// Applies a temporary effect (handled by inventory)
  void _applyTemporaryEffect(CandyItem candy) {
    // Temporary effects are managed by the inventory system
    // This method is called for consistency but the actual effect
    // is applied through the inventory's temporary effect system
  }

  /// Applies a special ability effect
  void _applySpecialAbility(CandyItem candy) {
    // Special abilities are handled through the inventory's temporary effect system
    // but we can add any immediate special ability logic here

    final abilityType = candy.abilityModifications.keys.first;
    switch (abilityType) {
      case 'freezeEnemies':
        // Freeze effect is handled by the inventory system
        break;

      case 'wallVision':
        // Wall vision effect is handled by the inventory system
        break;

      default:
        // Unknown special ability
        break;
    }
  }

  /// Applies a stat modification effect
  void _applyStatModification(CandyItem candy) {
    // Stat modifications are handled through the inventory's temporary effect system
    // but we can add any permanent stat modifications here if needed
  }

  /// Gets the effective maximum health including bonuses
  int getEffectiveMaxHealth() {
    final baseMaxHealth = character.maxHealth;
    final permanentBonus = _permanentStats['maxHealth'] ?? 0;
    final temporaryBonus = character.inventory
        .getTotalAbilityModification('maxHealthBonus')
        .round();

    return baseMaxHealth + permanentBonus + temporaryBonus;
  }

  /// Gets the effective movement speed including bonuses
  double getEffectiveSpeed() {
    const baseSpeed = 1.0;
    final speedMultiplier = character.inventory.getTotalAbilityModification(
      'speedMultiplier',
    );

    return baseSpeed * (1.0 + speedMultiplier);
  }

  /// Gets the effective ally damage bonus
  int getEffectiveAllyDamageBonus() {
    final permanentBonus = _permanentStats['allyDamage'] ?? 0;
    final temporaryBonus = character.inventory
        .getTotalAbilityModification('allyDamageBonus')
        .round();

    return permanentBonus + temporaryBonus;
  }

  /// Gets the effective luck value
  int getEffectiveLuck() {
    final permanentLuck = _permanentStats['luck'] ?? 0;
    final temporaryLuck = character.inventory
        .getTotalAbilityModification('luck')
        .round();

    return permanentLuck + temporaryLuck;
  }

  /// Checks if the character has a specific active ability
  bool hasActiveAbility(String abilityName) {
    return character.inventory.hasActiveAbility(abilityName);
  }

  /// Gets all currently active abilities
  List<String> getActiveAbilities() {
    final abilities = <String>[];

    // Check for special abilities
    if (hasActiveAbility('wallVision')) abilities.add('Wall Vision');
    if (hasActiveAbility('freezeEnemies')) abilities.add('Freeze Enemies');

    // Check for stat bonuses
    if (getEffectiveSpeed() > 1.0) abilities.add('Speed Boost');
    if (getEffectiveAllyDamageBonus() > 0) abilities.add('Ally Strength');
    if (getEffectiveLuck() > 0) abilities.add('Luck Boost');

    return abilities;
  }

  /// Gets a summary of all current stat modifications
  Map<String, dynamic> getStatSummary() {
    return {
      'maxHealth': getEffectiveMaxHealth(),
      'speed': getEffectiveSpeed(),
      'allyDamageBonus': getEffectiveAllyDamageBonus(),
      'luck': getEffectiveLuck(),
      'activeAbilities': getActiveAbilities(),
    };
  }

  /// Updates all temporary effects (should be called each turn)
  void updateEffects() {
    character.updateCandyEffects();
    _invalidateCache();

    // Notify listeners if any effects changed
    notifyListeners();
  }

  /// Resets all permanent stat modifications
  void resetPermanentStats() {
    _permanentStats.clear();
    _invalidateCache();
    notifyListeners();
  }

  /// Adds a permanent stat modification
  void addPermanentStat(String statName, int value) {
    _permanentStats[statName] = (_permanentStats[statName] ?? 0) + value;
    _invalidateCache();
    notifyListeners();
  }

  /// Removes a permanent stat modification
  void removePermanentStat(String statName) {
    _permanentStats.remove(statName);
    _invalidateCache();
    notifyListeners();
  }

  /// Invalidates the cached stats
  void _invalidateCache() {
    _cachedStats = null;
  }

  /// Called when the inventory changes
  void _onInventoryChanged() {
    _invalidateCache();
    notifyListeners();
  }

  /// Gets cached effective stats (recalculates if needed)
  Map<String, dynamic> get effectiveStats {
    _cachedStats ??= {
      'maxHealth': getEffectiveMaxHealth(),
      'speed': getEffectiveSpeed(),
      'allyDamageBonus': getEffectiveAllyDamageBonus(),
      'luck': getEffectiveLuck(),
      'wallVision': hasActiveAbility('wallVision'),
      'freezeEnemies': hasActiveAbility('freezeEnemies'),
    };

    return Map.from(_cachedStats!);
  }

  @override
  void dispose() {
    character.inventory.removeListener(_onInventoryChanged);
    super.dispose();
  }

  @override
  String toString() {
    final stats = getStatSummary();
    return 'AbilityManager(${stats.toString()})';
  }
}
