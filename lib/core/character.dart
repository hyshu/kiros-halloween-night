import 'package:vector_math/vector_math.dart';
import '../models/model_3d.dart';
import 'position.dart';
import 'character_movement_animation_system.dart';
import 'collision_detector.dart';

/// Base class for all characters in the game
abstract class Character {
  /// Global flag to skip model loading in test environments
  static bool isTestMode = false;

  /// Unique identifier for this character
  final String id;

  /// Current position in the game grid
  Position position;

  /// Path to the 3D model asset
  final String modelPath;

  /// Current health points
  int health;

  /// Maximum health points
  final int maxHealth;

  /// Whether this character is currently active (for performance optimization)
  bool isActive;

  /// Whether this character can move
  bool canMove;

  /// The loaded 3D model (null until loaded)
  Model3D? model;

  /// Whether the character is currently idle
  bool isIdle;

  Character({
    required this.id,
    required this.position,
    required this.modelPath,
    required this.health,
    required this.maxHealth,
    this.isActive = true,
    this.canMove = true,
    this.model,
    this.isIdle = true,
  });

  /// Returns the world coordinates for 3D rendering
  Vector3 get worldPosition {
    final (x, y, z) = position.toWorldCoordinates();
    return Vector3(x, y, z);
  }

  /// Returns the model matrix for 3D rendering
  Matrix4 get modelMatrix {
    final worldPos = worldPosition;
    return Matrix4.identity()..translateByVector3(worldPos);
  }

  /// Attempts to move to a new position with collision detection
  /// Returns true if the move was successful and no collision occurred
  bool moveTo(Position newPosition, [CollisionDetector? collisionDetector]) {
    if (!canMove) return false;
    
    // If collision detector provided, check for collisions
    if (collisionDetector != null) {
      if (!collisionDetector.canMoveTo(this, newPosition)) {
        return false;
      }
    }

    position = newPosition;
    isIdle = false;
    return true;
  }

  /// Attempts to move to a new position with animation and collision detection
  /// Returns a Future that completes when the animation finishes, or immediately if collision occurs
  Future<bool> moveToAnimated(
    Position newPosition,
    CharacterMovementAnimationSystem animationSystem, {
    CollisionDetector? collisionDetector,
    int? duration,
    MovementEasing? easing,
  }) async {
    if (!canMove) return false;
    
    // If collision detector provided, check for collisions
    if (collisionDetector != null) {
      if (!collisionDetector.canMoveTo(this, newPosition)) {
        return false;
      }
    }

    final fromPosition = position;

    // Update position immediately for game logic
    position = newPosition;
    isIdle = false;

    // Start animation from old position to new position
    await animationSystem.animateCharacterMovement(
      id,
      fromPosition,
      newPosition,
      duration: duration,
      easing: easing,
    );

    return true;
  }

  /// Takes damage and returns true if the character is still alive
  bool takeDamage(int damage) {
    health = (health - damage).clamp(0, maxHealth);
    return health > 0;
  }

  /// Heals the character by the specified amount
  void heal(int amount) {
    health = (health + amount).clamp(0, maxHealth);
  }

  /// Returns true if the character is alive
  bool get isAlive => health > 0;

  /// Returns true if the character is at full health
  bool get isFullHealth => health >= maxHealth;

  /// Returns the health percentage (0.0 to 1.0)
  double get healthPercentage => health / maxHealth;

  /// Loads the 3D model for this character
  Future<void> loadModel() async {
    if (model != null) return;

    // Skip model loading in test mode
    if (isTestMode) {
      return;
    }

    try {
      model = await Model3D.loadFromAssetCached(id, modelPath);
    } catch (e) {
      // Handle model loading error gracefully
      // In production, this would use proper logging
      assert(false, 'Failed to load model for character $id: $e');
    }
  }

  /// Sets the character to idle state
  void setIdle() {
    isIdle = true;
  }

  /// Sets the character to active state
  void setActive() {
    isIdle = false;
  }

  @override
  String toString() => '$runtimeType($id) at $position';
}
