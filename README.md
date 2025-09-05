# Kiro Halloween Night Game

## Overview
A 3D Halloween-themed survivor game built with Flutter GPU, featuring a graveyard scene with various spooky objects and characters. The game uses Flutter's experimental GPU rendering capabilities for hardware-accelerated 3D graphics.

## Features
- **3D Grid-Based Scene**: 10x10 grid system for object placement
- **Halloween Theme**: Complete with graveyards, zombies, ghosts, and other spooky elements
- **GPU Acceleration**: Leverages Flutter GPU for efficient 3D rendering
- **Dynamic Scene Management**: Add, remove, and manage 3D objects in real-time
- **Rich Asset Library**: Includes graveyard objects, characters, and food items

## Technical Architecture

### Core Components
- **GridSceneManager**: Manages the 10x10 grid layout and object placement
- **GridRenderer**: Handles 3D rendering using Flutter GPU
- **Model3D**: Loads and manages 3D models from OBJ files
- **TextureManager**: Handles texture loading and management
- **Shaders**: Custom shader implementation for rendering effects

### Technology Stack
- **Flutter SDK**: ^3.9.0
- **Flutter GPU**: Experimental GPU rendering API
- **Flutter GPU Shaders**: ^0.3.0
- **Vector Math**: ^2.1.4 for 3D transformations

## Project Structure
```
kiro_halloween_game/
├── lib/
│   ├── main.dart                 # Application entry point
│   ├── grid_scene_manager.dart   # Grid-based scene management
│   ├── grid_renderer.dart        # 3D rendering implementation
│   ├── model_3d.dart             # 3D model loading and management
│   ├── texture_manager.dart      # Texture handling
│   ├── obj_parser.dart           # OBJ file parser
│   ├── multi_model_renderer.dart # Multi-model rendering
│   ├── scene_manager.dart        # Base scene management
│   └── shaders.dart              # Shader definitions
├── assets/
│   ├── graveyard/               # Graveyard-themed 3D models
│   │   ├── *.obj                # 3D models (graves, fences, crypts, etc.)
│   │   └── Textures/            # Model textures
│   ├── characters/              # Character models
│   │   ├── *.obj                # Ghost, zombie, skeleton models
│   │   └── Textures/            # Character textures
│   ├── foods/                   # Food item models
│   │   ├── *.obj                # Various food models
│   │   └── Textures/            # Food textures
│   └── shaderbundles/           # Compiled shader bundles
└── pubspec.yaml                 # Project dependencies
```

## Game Characters

### Player Character
- **Ghost** - The player controls a ghost character navigating through the haunted graveyard

### Enemy Characters (Most of Humans)
- **character-female-a** through **character-female-f** - Female human enemies
- **character-male-a** through **character-male-f** - Male human enemies
- **Zombie** - Undead enemies
- **Skeleton** - Bone warrior enemies
- **Vampire** - Vampiric enemies
- **Digger** - Grave digger enemies

## Available Environment Objects

### Structures & Buildings
- **Crypts**: crypt, crypt-small, crypt-large, crypt-small-entrance, crypt-small-entrance-alternative, crypt-door, crypt-small-roof, crypt-large-roof
- **Altars**: altar-stone, altar-wood
- **Columns & Pillars**: column-large, pillar-large, pillar-small, pillar-square, pillar-obelisk, border-pillar, cross-column

### Grave Markers & Tombstones
- **Gravestones**: gravestone-bevel, gravestone-broken, gravestone-cross, gravestone-cross-large, gravestone-decorative, gravestone-flat, gravestone-flat-open, gravestone-roof, gravestone-round, gravestone-wide, gravestone-debris
- **Crosses**: cross, cross-wood
- **Graves**: grave, grave-border

### Walls & Fences
- **Brick Walls**: brick-wall, brick-wall-curve, brick-wall-curve-small, brick-wall-end
- **Stone Walls**: stone-wall, stone-wall-curve, stone-wall-damaged, stone-wall-column
- **Wooden Fences**: fence, fence-damaged, fence-gate
- **Iron Fences**: iron-fence, iron-fence-bar, iron-fence-border, iron-fence-border-column, iron-fence-border-curve, iron-fence-border-gate, iron-fence-curve, iron-fence-damaged

### Trees & Nature
- **Pine Trees**: pine, pine-crooked, pine-fall, pine-fall-crooked
- **Wood Elements**: trunk, trunk-long, debris-wood, debris
- **Rocks**: rocks, rocks-tall

### Decorative Items
- **Lighting**: lantern-candle, lantern-glass, lightpost-single, lightpost-double, lightpost-all, fire-basket
- **Candles**: candle, candle-multiple
- **Halloween**: pumpkin, pumpkin-carved, pumpkin-tall, pumpkin-tall-carved

### Cemetery Objects
- **Coffins**: coffin, coffin-old
- **Benches**: bench, bench-damaged
- **Tools**: shovel, shovel-dirt
- **Containers**: urn, barrel
- **Details**: detail-bowl, detail-chalice, detail-plate

### Terrain & Paths
- **Road**: road
- **Hay**: hay-bale, hay-bale-bundled

### Food Items (Collectibles/Power-ups)
- **Fruits**: apple, apple-half, avocado, banana, beet
- **Vegetables**: broccoli
- **Meat**: bacon, bacon-raw
- **Containers**: bag, bag-flat, barrel, bowl, bowl-broth, bowl-cereal, bowl-soup
- **Condiments**: bottle-ketchup, bottle-mustard, bottle-oil
- **Other**: bread
- And many more food items available in assets/foods/

## Getting Started

### Prerequisites
- Flutter SDK (with GPU support enabled)
- Dart SDK ^3.9.0
- Development environment supporting Flutter GPU features

### Installation
1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd kiro_halloween_game
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Compile shaders (if needed):
   ```bash
   ./compile_shader.sh
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## Usage

### Scene Controls
- **Reset Scene**: Click the refresh button to reset to the default graveyard layout
- **Clear Scene**: Click the clear button to remove all objects

### Default Scene Layout
The game initializes with a pre-configured graveyard scene featuring:
- Fence perimeter around the 10x10 grid
- Central crypt structure
- Scattered grave markers
- Trees for atmosphere
- Character spawns (zombie, ghost, skeleton)
- Decorative lanterns

### Grid System
Objects are placed on a 10x10 grid where:
- Each grid cell can contain one 3D object
- Objects are automatically positioned with 2.0 unit spacing
- Grid coordinates range from (0,0) to (9,9)

## Development

### Adding New Models
1. Place OBJ files in the appropriate assets directory
2. Add corresponding textures to the Textures subdirectory
3. Update `pubspec.yaml` if adding new asset directories
4. Models can be loaded using the `Model3D.loadFromAsset()` method

### Modifying the Scene
Edit the pattern array in `main.dart` to change the default scene layout:
```dart
final pattern = [
  ['fence', 'fence', ...],
  ['fence', null, 'tree', ...],
  // ...
];
```

### Custom Shaders
Shaders are defined in `lib/shaders.dart` and compiled into bundles. Modify and recompile as needed for custom rendering effects.

## Performance Considerations
- The game uses Flutter GPU for hardware acceleration
- Models are loaded asynchronously to prevent UI blocking
- Grid-based system limits objects to improve performance
- Texture management optimizes memory usage

## Future Enhancements
- Player character control
- Interactive objects
- Lighting effects
- Sound effects and ambient music
- Save/load functionality
- Level editor
- Animation support
- Particle effects

## License
MIT