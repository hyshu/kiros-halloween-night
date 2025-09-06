# Kiro Ghost Roguelike - Design Document

## Overview

The Kiro Ghost Roguelike is a 3D adventure game built on Flutter's GPU rendering system where players control Kiro, a ghost character, through a vast procedurally-generated world. The game features strategic gameplay through candy collection, enemy interaction via gift-giving mechanics, and ally recruitment leading to a climactic boss battle.

The design leverages the existing 3D asset library and rendering infrastructure while introducing roguelike mechanics, strategic combat, and a unique social interaction system that transforms enemies into allies through candy gifts.

## Architecture

### Core Game Loop
The game follows a turn-based movement system with real-time 3D rendering:
1. Player input processing for movement and actions
2. Active enemy AI processing (proximity-based activation)
3. Collision detection and movement validation
4. Combat resolution between allies and hostile enemies
5. Event processing and dialogue updates
6. 3D scene rendering and camera updates

### System Architecture
```
Game Engine Layer
├── Input Manager (movement, interaction commands)
├── World Manager (map generation, tile management)
├── Entity Manager (characters, items, collision)
├── Combat System (ally vs enemy interactions)
├── Inventory System (candy collection and usage)
├── Dialogue System (events, story, feedback)
└── Rendering Manager (3D models, camera, lighting)
```

### Performance Optimization Strategy
- **Proximity-based activation**: Only enemies within detection radius are actively processed
- **Spatial partitioning**: Large world divided into chunks for efficient collision detection
- **Asset streaming**: 3D models loaded/unloaded based on camera proximity
- **Batch rendering**: Similar objects rendered together to minimize draw calls

## Components and Interfaces

### World Generation System
**Purpose**: Creates the 500x1000 tile procedural world with guaranteed pathfinding and complete boundary enforcement

**Key Components**:
- `WorldGenerator`: Procedural map creation with maze-like pathways and boss placement
- `TileMap`: Grid-based world representation with tile types (floor, wall, obstacle)
- `PathValidator`: Ensures navigable route from spawn to boss location at end of main path
- `PerimeterWalls`: Enforces complete world boundaries with impassable barriers and no escape gaps
- `BossLocationManager`: Places final boss monster at the designated end location

**Design Rationale**: Large world size provides epic scope while grid-based system simplifies collision detection and pathfinding. Complete perimeter walls prevent players from escaping the play area, ensuring contained gameplay. Boss placement at path end creates clear progression goal.

### Character System
**Purpose**: Manages Kiro, enemies, and ally state transitions with proper 3D model integration

**Key Components**:
- `GhostCharacter`: Player-controlled Kiro using ghost 3D model with grid-based movement and inventory
- `EnemyCharacter`: AI-controlled entities using human/monster 3D models with proximity activation
- `AllyCharacter`: Converted enemies that follow Kiro and engage in combat
- `CharacterController`: Handles movement validation, collision detection, and idle state management
- `MovementValidator`: Ensures characters cannot pass through walls or obstacles

**Design Rationale**: Separate character types allow for distinct behaviors while sharing common movement and rendering interfaces. Grid-based movement system provides strategic positioning. State pattern enables smooth enemy-to-ally transitions with proper 3D model representation.

### Candy and Inventory System
**Purpose**: Strategic resource management and enemy interaction mechanics with ability enhancement

**Key Components**:
- `CandyItem`: Individual candy using food 3D models with unique abilities and stat modifications
- `Inventory`: Player's candy collection with viewing and usage capabilities
- `CandySpawner`: Random placement of candy items across the world during map generation
- `GiftSystem`: Interface for giving candy to adjacent enemies with selection options
- `AbilityManager`: Applies candy effects and stat modifications to Kiro
- `CollectionSystem`: Handles automatic candy pickup when Kiro moves onto candy tiles

**Design Rationale**: Using food 3D models as candy provides visual variety and thematic consistency. Each candy type offers different strategic advantages through abilities and stat modifications, encouraging exploration and tactical decision-making. Automatic collection simplifies gameplay while gift system adds strategic depth.

### Combat and Ally System
**Purpose**: Strategic combat between allies and hostile enemies with lifecycle management

**Key Components**:
- `CombatManager`: Orchestrates battles between allied and hostile enemies
- `AllyAI`: Following behavior and automatic combat engagement for converted enemies
- `HealthSystem`: Damage tracking with satisfaction-based removal system
- `CombatResolver`: Determines attack outcomes and health changes
- `AllyLifecycleManager`: Handles ally satisfaction and disappearance when health reaches zero
- `CombatFeedbackSystem`: Provides dialogue updates during combat encounters

**Design Rationale**: Allies provide strategic depth by fighting hostile enemies automatically. The "satisfaction" mechanic (allies disappearing when health reaches zero) prevents overwhelming ally accumulation while maintaining narrative consistency. Combat feedback through dialogue keeps players informed of battle outcomes.

### Proximity and Activation System
**Purpose**: Performance optimization through selective enemy processing and dynamic encounters

**Key Components**:
- `ProximityDetector`: Calculates distances between Kiro and enemies for activation
- `ActivationManager`: Enables/disables enemy AI and movement based on proximity thresholds
- `SpatialIndex`: Efficient spatial queries for nearby entities
- `EnemyStateManager`: Handles transitions between active/inactive enemy states

**Design Rationale**: Only processing nearby enemies maintains performance in the large 500x1000 world while creating dynamic encounters as players explore. Enemies become active and potentially hostile when Kiro approaches, then deactivate when distance increases, optimizing computational resources.

### Dialogue and Event System
**Purpose**: Provides narrative feedback and story progression through interactive dialogue

**Key Components**:
- `DialogueManager`: Displays and manages dialogue windows for game events
- `EventSystem`: Triggers appropriate dialogue for interactions and story moments
- `DialogueRenderer`: Handles dialogue window display and user interaction
- `NarrativeController`: Manages story progression and contextual dialogue
- `FeedbackSystem`: Provides descriptive text for item collection and game events

**Design Rationale**: Centralized dialogue system ensures consistent narrative delivery across all game interactions. Event-driven architecture allows for contextual dialogue based on player actions, enemy interactions, and story progression.

### Boss Battle System
**Purpose**: Provides climactic final encounter with special mechanics and victory conditions

**Key Components**:
- `BossCharacter`: Special enemy with enhanced abilities and unique combat mechanics
- `BossEncounterManager`: Handles boss battle initiation and special combat rules
- `VictoryConditionChecker`: Monitors boss defeat and triggers victory state
- `BossDialogueSystem`: Provides battle-specific dialogue and narrative elements
- `SpecialCombatMechanics`: Implements boss-specific abilities and interactions

**Design Rationale**: Boss system provides satisfying conclusion to the adventure while maintaining compatibility with existing candy and ally systems. Special mechanics differentiate boss encounters from regular combat while preserving strategic elements.

## Data Models

### World Data
```dart
class TileMap {
  final int width = 500;
  final int height = 1000;
  final List<List<TileType>> tiles;
  final Position bossLocation;
  final Position playerSpawn;
}

enum TileType {
  floor,
  wall,
  obstacle,
  candy
}
```

### Character Data
```dart
abstract class Character {
  Position position;
  String modelPath;
  int health;
  bool isActive;
  bool canMove;
}

class GhostCharacter extends Character {
  Inventory inventory;
  List<AllyCharacter> allies;
  bool isIdle;
  Map<String, dynamic> abilities; // candy-granted abilities
}

class EnemyCharacter extends Character {
  EnemyState state; // hostile, ally, satisfied
  int activationRadius;
  bool isProximityActive;
}

class BossCharacter extends EnemyCharacter {
  Map<String, dynamic> specialAbilities;
  bool isBossEncounterActive;
}
```

### Candy System
```dart
class CandyItem {
  final String name;
  final String modelPath; // from assets/foods
  final CandyEffect effect;
  final int value;
  final Map<String, dynamic> abilityModifications;
}

enum CandyEffect {
  healthBoost,
  speedIncrease,
  allyStrength,
  specialAbility,
  statModification
}

class Inventory {
  List<CandyItem> candyItems;
  bool canViewItems;
  
  void addCandy(CandyItem candy);
  void removeCandy(CandyItem candy);
  List<CandyItem> getAvailableCandy();
}
```

### Dialogue System
```dart
class DialogueEvent {
  final String message;
  final DialogueType type;
  final bool canAdvance;
  final bool canDismiss;
}

enum DialogueType {
  interaction,
  itemCollection,
  combat,
  story,
  boss
}

class DialogueWindow {
  bool isActive;
  DialogueEvent currentEvent;
  
  void displayDialogue(DialogueEvent event);
  void advanceDialogue();
  void dismissDialogue();
}
```

### Collision System
```dart
class CollisionDetector {
  bool canMoveTo(Position from, Position to, TileMap map);
  bool isValidPosition(Position position, TileMap map);
  List<Character> getCharactersAt(Position position);
}

enum MovementResult {
  success,
  blockedByWall,
  blockedByObstacle,
  blockedByCharacter,
  outOfBounds
}
```

## Error Handling

### Movement Validation
- **Invalid moves**: Graceful rejection with position maintenance and appropriate feedback
- **Boundary checks**: Prevent movement outside complete world perimeter with no escape gaps
- **Collision detection**: Real-time validation against walls, obstacles, and other characters
- **Wall/obstacle blocking**: Ensure no character can pass through impassable terrain
- **Pathfinding failures**: Alternative route suggestions or movement blocking with user feedback

### Combat System
- **Invalid targets**: Prevent attacks on non-existent or friendly entities
- **Health underflow**: Ensure health never goes below zero
- **Ally overflow**: Limit maximum number of active allies for performance
- **Combat state conflicts**: Resolve simultaneous attack scenarios

### Resource Management
- **Asset loading failures**: Fallback to default models or error placeholders
- **Memory constraints**: Automatic cleanup of distant or inactive entities
- **Save state corruption**: Validation and recovery mechanisms
- **Performance degradation**: Dynamic quality adjustment based on frame rate

### Dialogue System Errors
- **Missing dialogue events**: Fallback to generic messages for undefined interactions
- **Dialogue state conflicts**: Prevent multiple dialogue windows from appearing simultaneously
- **Event trigger failures**: Graceful handling when story events fail to activate
- **User input validation**: Ensure dialogue advancement and dismissal work reliably

### Boss Battle Errors
- **Boss encounter failures**: Fallback mechanisms if boss battle fails to initiate
- **Victory condition bugs**: Robust checking to ensure proper game completion
- **Special mechanic failures**: Graceful degradation if boss abilities malfunction
- **Battle state corruption**: Recovery mechanisms for interrupted boss encounters

## Testing Strategy

### Unit Testing
- **Movement validation**: Test collision detection, boundary enforcement, and wall/obstacle blocking
- **Combat mechanics**: Verify damage calculation, health management, and ally satisfaction system
- **Inventory operations**: Validate candy collection, ability application, and gift system
- **World generation**: Ensure valid paths, proper boundary creation, and boss placement
- **Dialogue system**: Test event triggering, message display, and user interaction
- **Proximity activation**: Verify enemy activation/deactivation based on distance thresholds

### Integration Testing
- **Character interactions**: Test enemy-to-ally conversion process and candy gift mechanics
- **Rendering pipeline**: Verify 3D model loading and display for all asset types
- **Performance benchmarks**: Measure frame rates with maximum entities and proximity activation
- **Boss battle integration**: Test boss encounter initiation and victory conditions
- **Dialogue integration**: Verify dialogue appears correctly for all game events
- **Complete world traversal**: Test movement across entire 500x1000 map with boundary enforcement

### User Experience Testing
- **Control responsiveness**: Ensure smooth grid-based character movement and idle states
- **Visual clarity**: Verify 3D models are distinguishable and well-lit across all asset types
- **Gameplay balance**: Test candy distribution, ability effects, and combat difficulty
- **Story progression**: Validate dialogue system, narrative flow, and boss encounter
- **Strategic depth**: Test candy gift mechanics and ally management systems
- **World exploration**: Verify epic scope feeling and navigation clarity in large world

### Performance Testing
- **Large world navigation**: Test movement across entire 500x1000 map
- **Maximum entity count**: Stress test with many active enemies and allies
- **Memory usage**: Monitor asset loading and cleanup efficiency
- **Frame rate stability**: Ensure consistent performance during combat

## Technical Considerations

### 3D Asset Integration
The game leverages existing 3D models from the assets folder as specified in requirements:
- **Ghost character**: `assets/graveyard/character-ghost.obj` for Kiro with idle animation support
- **Human/monster models**: `assets/characters/character-*.obj` and `assets/graveyard/character-*.obj` for enemies and allies
- **Food models**: `assets/foods/*` for candy items with random distribution across the world
- **Boss character**: Special monster model from available assets for final encounter
- **Environmental assets**: Additional models for world decoration and obstacle representation

### Camera System
- **Isometric view**: Provides clear visibility of grid-based movement
- **Dynamic following**: Camera tracks Kiro with smooth interpolation
- **Zoom capabilities**: Allow players to see more of the large world
- **Collision avoidance**: Prevent camera clipping through world geometry

### Lighting and Atmosphere
- **Ambient lighting**: Ensures all areas are visible for gameplay
- **Dynamic shadows**: Enhance 3D model depth and visual appeal
- **Atmospheric effects**: Create appropriate mood for ghost adventure
- **Performance optimization**: Balance visual quality with frame rate

This design provides a solid foundation for implementing the Kiro Ghost Roguelike while leveraging the existing Flutter GPU 3D rendering system and asset library. The modular architecture allows for iterative development and easy expansion of features.