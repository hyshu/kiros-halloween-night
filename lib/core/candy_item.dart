import 'package:vector_math/vector_math.dart';
import '../models/model_3d.dart';
import 'position.dart';
import '../l10n/strings.g.dart';

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
          name: t.candyTypes.candyBar.name,
          modelPath: 'assets/foods/candy-bar.obj',
          effect: CandyEffect.healthBoost,
          value: 20,
          description: t.candyTypes.candyBar.description,
          position: position,
        );

      case CandyType.chocolate:
        return CandyItem(
          id: id,
          name: t.candyTypes.chocolate.name,
          modelPath: 'assets/foods/chocolate.obj',
          effect: CandyEffect.maxHealthIncrease,
          value: 10,
          description: t.candyTypes.chocolate.description,
          position: position,
        );

      case CandyType.cookie:
        return CandyItem(
          id: id,
          name: t.candyTypes.cookie.name,
          modelPath: 'assets/foods/cookie.obj',
          effect: CandyEffect.healthBoost,
          value: 18,
          description: t.candyTypes.cookie.description,
          position: position,
        );

      case CandyType.cupcake:
        return CandyItem(
          id: id,
          name: t.candyTypes.cupcake.name,
          modelPath: 'assets/foods/cupcake.obj',
          effect: CandyEffect.allyStrength,
          value: 5,
          abilityModifications: {'allyDamageBonus': 5, 'duration': 20},
          description: t.candyTypes.cupcake.description,
          position: position,
        );

      case CandyType.donut:
        return CandyItem(
          id: id,
          name: t.candyTypes.donut.name,
          modelPath: 'assets/foods/donut.obj',
          effect: CandyEffect.healthBoost,
          value: 15,
          description: t.candyTypes.donut.description,
          position: position,
        );

      case CandyType.iceCream:
        return CandyItem(
          id: id,
          name: t.candyTypes.iceCream.name,
          modelPath: 'assets/foods/ice-cream.obj',
          effect: CandyEffect.specialAbility,
          value: 1,
          abilityModifications: {'freezeEnemies': true, 'duration': 10},
          description: t.candyTypes.iceCream.description,
          position: position,
        );

      case CandyType.lollipop:
        return CandyItem(
          id: id,
          name: t.candyTypes.lollipop.name,
          modelPath: 'assets/foods/lollypop.obj',
          effect: CandyEffect.healthBoost,
          value: 22,
          description: t.candyTypes.lollipop.description,
          position: position,
        );

      case CandyType.popsicle:
        return CandyItem(
          id: id,
          name: t.candyTypes.popsicle.name,
          modelPath: 'assets/foods/popsicle.obj',
          effect: CandyEffect.healthBoost,
          value: 12,
          description: t.candyTypes.popsicle.description,
          position: position,
        );

      case CandyType.gingerbread:
        return CandyItem(
          id: id,
          name: t.candyTypes.gingerbread.name,
          modelPath: 'assets/foods/ginger-bread.obj',
          effect: CandyEffect.specialAbility,
          value: 1,
          abilityModifications: {'wallVision': true, 'duration': 15},
          description: t.candyTypes.gingerbread.description,
          position: position,
        );

      case CandyType.muffin:
        return CandyItem(
          id: id,
          name: t.candyTypes.muffin.name,
          modelPath: 'assets/foods/muffin.obj',
          effect: CandyEffect.healthBoost,
          value: 25,
          description: t.candyTypes.muffin.description,
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
