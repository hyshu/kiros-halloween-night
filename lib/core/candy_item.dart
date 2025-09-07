import 'package:vector_math/vector_math.dart';
import '../models/model_3d.dart';
import 'position.dart';

/// Represents different types of candy effects
enum CandyEffect {
  /// Restores health points
  healthBoost,

  /// Increases movement speed temporarily
  speedIncrease,

  /// Increases maximum health permanently
  maxHealthIncrease,

  /// Increases ally combat strength
  allyStrength,

  /// Provides special abilities like seeing through walls
  specialAbility,

  /// General stat modifications
  statModification,
}

/// Represents a candy item that can be collected and used
class CandyItem {
  /// Unique identifier for this candy item
  final String id;

  /// Display name of the candy
  final String name;

  /// Path to the 3D model asset from assets/foods
  final String modelPath;

  /// Type of effect this candy provides
  final CandyEffect effect;

  /// Numerical value for the effect (e.g., health points, speed multiplier)
  final int value;

  /// Additional ability modifications this candy provides
  final Map<String, dynamic> abilityModifications;

  /// Description of what this candy does
  final String description;

  /// Position in the world (if placed on the map)
  Position? position;

  /// The loaded 3D model (null until loaded)
  Model3D? model;

  /// Whether this candy has been collected
  bool isCollected = false;

  CandyItem({
    required this.id,
    required this.name,
    required this.modelPath,
    required this.effect,
    required this.value,
    this.abilityModifications = const {},
    required this.description,
    this.position,
    this.model,
  });

  /// Factory constructor for creating different types of candy
  factory CandyItem.create(CandyType type, String id, {Position? position}) {
    switch (type) {
      case CandyType.candyBar:
        return CandyItem(
          id: id,
          name: 'Candy Bar',
          modelPath: 'assets/foods/candy-bar.obj',
          effect: CandyEffect.healthBoost,
          value: 20,
          description: 'A sweet candy bar that restores 20 health points',
          position: position,
        );

      case CandyType.chocolate:
        return CandyItem(
          id: id,
          name: 'Chocolate',
          modelPath: 'assets/foods/chocolate.obj',
          effect: CandyEffect.maxHealthIncrease,
          value: 10,
          description:
              'Rich chocolate that permanently increases max health by 10',
          position: position,
        );

      case CandyType.cookie:
        return CandyItem(
          id: id,
          name: 'Cookie',
          modelPath: 'assets/foods/cookie.obj',
          effect: CandyEffect.speedIncrease,
          value: 2,
          abilityModifications: {'speedMultiplier': 1.5, 'duration': 30},
          description:
              'A crispy cookie that increases movement speed for 30 turns',
          position: position,
        );

      case CandyType.cupcake:
        return CandyItem(
          id: id,
          name: 'Cupcake',
          modelPath: 'assets/foods/cupcake.obj',
          effect: CandyEffect.allyStrength,
          value: 5,
          abilityModifications: {'allyDamageBonus': 5, 'duration': 20},
          description:
              'A delicious cupcake that boosts ally combat strength for 20 turns',
          position: position,
        );

      case CandyType.donut:
        return CandyItem(
          id: id,
          name: 'Donut',
          modelPath: 'assets/foods/donut.obj',
          effect: CandyEffect.healthBoost,
          value: 15,
          description: 'A glazed donut that restores 15 health points',
          position: position,
        );

      case CandyType.iceCream:
        return CandyItem(
          id: id,
          name: 'Ice Cream',
          modelPath: 'assets/foods/ice-cream.obj',
          effect: CandyEffect.specialAbility,
          value: 1,
          abilityModifications: {'freezeEnemies': true, 'duration': 10},
          description:
              'Cool ice cream that freezes nearby enemies for 10 turns',
          position: position,
        );

      case CandyType.lollipop:
        return CandyItem(
          id: id,
          name: 'Lollipop',
          modelPath: 'assets/foods/lollypop.obj',
          effect: CandyEffect.statModification,
          value: 3,
          abilityModifications: {'luck': 3, 'duration': 25},
          description: 'A colorful lollipop that increases luck for 25 turns',
          position: position,
        );

      case CandyType.popsicle:
        return CandyItem(
          id: id,
          name: 'Popsicle',
          modelPath: 'assets/foods/popsicle.obj',
          effect: CandyEffect.healthBoost,
          value: 12,
          description: 'A refreshing popsicle that restores 12 health points',
          position: position,
        );

      case CandyType.gingerbread:
        return CandyItem(
          id: id,
          name: 'Gingerbread',
          modelPath: 'assets/foods/ginger-bread.obj',
          effect: CandyEffect.specialAbility,
          value: 1,
          abilityModifications: {'wallVision': true, 'duration': 15},
          description:
              'Magical gingerbread that allows seeing through walls for 15 turns',
          position: position,
        );

      case CandyType.muffin:
        return CandyItem(
          id: id,
          name: 'Muffin',
          modelPath: 'assets/foods/muffin.obj',
          effect: CandyEffect.healthBoost,
          value: 25,
          description: 'A hearty muffin that restores 25 health points',
          position: position,
        );
    }
  }

  /// Returns the world coordinates for 3D rendering
  Vector3 get worldPosition {
    if (position == null) return Vector3.zero();
    final (x, y, z) = position!.toWorldCoordinates();
    return Vector3(x, y, z);
  }

  /// Returns the model matrix for 3D rendering
  Matrix4 get modelMatrix {
    final worldPos = worldPosition;
    return Matrix4.identity()..translateByVector3(worldPos);
  }

  /// Loads the 3D model for this candy item
  Future<void> loadModel() async {
    if (model != null) return;

    try {
      model = await Model3D.loadFromAssetCached(id, modelPath);
    } catch (e) {
      // Handle model loading error gracefully
      // In production, this would use proper logging
      assert(false, 'Failed to load model for candy $id: $e');
    }
  }

  /// Marks this candy as collected
  void collect() {
    isCollected = true;
  }

  /// Returns true if this candy provides a temporary effect
  bool get isTemporaryEffect {
    return abilityModifications.containsKey('duration');
  }

  /// Returns the duration of the effect (0 if permanent)
  int get effectDuration {
    return abilityModifications['duration'] as int? ?? 0;
  }

  /// Returns a copy of this candy item with a new ID and position
  CandyItem copyWith({String? id, Position? position}) {
    return CandyItem(
      id: id ?? this.id,
      name: name,
      modelPath: modelPath,
      effect: effect,
      value: value,
      abilityModifications: Map.from(abilityModifications),
      description: description,
      position: position ?? this.position,
    );
  }

  @override
  String toString() => '$name ($id) at $position - $description';
}

/// Enumeration of available candy types
enum CandyType {
  candyBar,
  chocolate,
  cookie,
  cupcake,
  donut,
  iceCream,
  lollipop,
  popsicle,
  gingerbread,
  muffin,
}
