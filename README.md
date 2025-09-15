# Kiro's Halloween Night 🎃👻

**Created for the Code With Kiro Hackathon**

Learn more: [DevPost](https://kiro.devpost.com/?trk=b85f313f-a67c-452d-b088-07f0ddbd7e15&sc_channel=el) and 
[Project Page](https://devpost.com/software/kiro-s-halloween-night?ref_content=my-projects-tab&ref_feature=my_projects)

A 3D Halloween-themed RPG game built with Flutter GPU. Navigate through a massive 100x200 world, convert enemies into allies with candy gifts, and defeat the final boss.

## Game Features

### 🎮 Core Gameplay
- **Turn-based Combat**: Strategic battle system with 5-phase animations
- **Ally System**: Convert enemies into allies using candy gifts (max 10 allies)
- **Massive World**: Procedurally generated 100x200 tile world
- **RPG Elements**: HP management, inventory system, abilities, and progression
- **Boss Battle**: Final confrontation with the powerful Vampire Lord

### 🍭 Candy System
- **150+ Candy Types**: Various items with unique effects and abilities
- **Strategic Gifting**: Give candy to enemies to convert them into allies
- **Temporary Effects**: Boost abilities, health, and special powers
- **Inventory Management**: Limited slots requiring strategic item management

### 🎯 Game Objectives
- **Survival**: Maintain player HP while exploring the world
- **Ally Collection**: Build an army by converting enemies with candy gifts
- **Boss Defeat**: Take down the final boss Vampire Lord
- **Statistics**: Track enemies defeated, candies given, and survival time

## Technical Specifications

### 🚀 Flutter GPU Technology
- **3D Rendering**: Custom shader-based high-performance graphics
- **Matrix Transformations**: Advanced 3D coordinate transformations and camera control
- **Depth Testing**: Accurate 3D object rendering with proper depth sorting
- **Texture Mapping**: OBJ model loading with texture support

### 🎨 Graphics Features
- **Camera Controls**: Pan, zoom, and rotation with gesture support
- **Animation System**: Smooth character movement and combat animations
- **UI Overlays**: HP bars, coordinate display, inventory management
- **Performance Optimization**: Efficient rendering for large-scale worlds

### 🧠 AI Systems
- **Enemy AI**: Intelligent enemies that track and attack the player
- **Ally AI**: Supportive allies that assist in combat and follow the player
- **Pathfinding**: A* algorithm for optimal route finding
- **Collision Detection**: Prevents character overlap and handles movement constraints

## Controls

### ⌨️ Keyboard Controls
- **Movement**: `Arrow Keys` or `WASD` - Move character in four directions
- **Attack**: Press movement key toward an enemy to attack
- **Inventory**: `I` key - Open candy inventory menu
- **Gift**: `G` key - Give candy to adjacent enemies

### 🖱️ Mouse Controls
- **Camera Rotation**: Drag to change viewing angle
- **Zoom**: Pinch or scroll to zoom in/out
- **Pan**: Single finger drag to move camera position

### 📱 UI Interactions
- **Inventory**: Use candy for healing or select gifts for enemies
- **Dialogue**: Combat messages and story progression
- **Statistics**: View HP, coordinates, enemy count, and game stats

## Setup & Installation

### 🔧 Requirements
- **Flutter SDK**: ^3.9.0
- **Dart SDK**: ^3.9.0
- **macOS**: Primary supported platform
- **Flutter GPU**: Experimental features enabled

### 📦 Installation

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the game**:
   ```bash
   flutter run -d macOS --release
   ```

## Project Structure

```
kiro_halloween_game/
├── lib/
│   ├── core/                     # Core game logic
│   │   ├── ghost_character.dart  # Player character (Kiro the ghost)
│   │   ├── enemy_character.dart  # Enemy characters and AI
│   │   ├── ally_character.dart   # Ally characters and AI
│   │   ├── game_loop_manager.dart # Turn-based game loop management
│   │   ├── world_generator.dart  # Procedural world generation
│   │   ├── candy_item.dart       # Candy items and effects
│   │   ├── combat_manager.dart   # Combat system
│   │   ├── gift_system.dart      # Enemy conversion system
│   │   └── ...                   # Other core systems
│   ├── rendering/                # 3D rendering system
│   │   ├── grid_renderer.dart    # Main 3D renderer with Flutter GPU
│   │   └── multi_model_renderer.dart # Multi-object rendering
│   ├── scene/                    # Scene management
│   │   └── grid_scene_manager.dart # 3D scene and object management
│   ├── managers/                 # Various game managers
│   │   ├── input_manager.dart    # Keyboard and input handling
│   │   ├── model_manager.dart    # 3D model loading and caching
│   │   └── texture_manager.dart  # Texture management
│   ├── widgets/                  # UI components
│   │   ├── dialogue_ui.dart      # Combat and story messages
│   │   ├── inventory_ui.dart     # Candy inventory interface
│   │   └── gift_ui.dart          # Gift selection interface
│   ├── screens/                  # Game screens
│   │   ├── start_screen.dart     # Main menu
│   │   ├── game_over_screen.dart # End game statistics
│   │   └── story_dialogue.dart   # Opening story
│   └── l10n/                     # Internationalization
├── assets/
│   ├── graveyard/                # Graveyard environment objects
│   │   ├── *.obj                 # 3D models (graves, crypts, fences)
│   │   └── Textures/             # Object textures
│   ├── characters/               # Character models
│   │   ├── *.obj                 # Ghost, zombie, skeleton, vampire models
│   │   └── Textures/             # Character textures
│   ├── foods/                    # Candy item models
│   │   ├── *.obj                 # Various candy models
│   │   └── Textures/             # Candy textures
│   └── shaderbundles/            # Compiled GPU shaders
└── test/                         # Test suite (33 files, 8,472 lines)
    └── core/                     # Core system tests
```

## Game Screens

### 🎪 Main Game Screen
- **3D World View**: Real-time 3D rendering of the game world
- **HP Bar**: Player health display in bottom-right corner
- **Coordinates**: Current position display in bottom-left corner
- **Control Guide**: Movement and inventory operation instructions

### 🎒 Inventory Screen
- **Candy List**: Display of collected candy items with icons
- **Use Button**: Consume candy for HP restoration or ability boosts
- **Gift Button**: Select candy to give to adjacent enemies
- **Effect Description**: Detailed explanation of each candy's effects

### 💬 Dialogue System
- **Combat Messages**: Attack results and battle outcomes
- **Story Dialogue**: Opening narrative and character interactions
- **Collection Notifications**: Candy discovery and pickup messages
- **Boss Encounters**: Special dialogue for boss battles

## Development & Testing

### 🧪 Running Tests
```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/core/ghost_character_test.dart

# Run tests with coverage
flutter test --coverage
```

### 🔍 Debug Mode Features
Debug mode displays additional information:
- **Object Count**: Number of objects in the scene
- **Combat Statistics**: Active combat encounters
- **Enemy Information**: Total and active enemy counts
- **Performance Metrics**: FPS and memory usage
- **Player Stats**: HP, combat strength, ally count

### 📊 Test Coverage
- **33 Test Files**: Comprehensive test suite with 8,472 lines of test code
- **Core Systems**: All major game systems thoroughly tested
- **Integration Tests**: Cross-system functionality verification
- **Performance Tests**: World generation and rendering performance

## Performance Optimization

### ⚡ Optimization Features
- **Device-Private Textures**: GPU memory efficiency improvements
- **Batch Rendering**: Reduced draw calls for better performance
- **Memory Management**: Proper resource allocation and cleanup
- **LOD System**: Level-of-detail adjustments based on camera distance
- **Culling**: Off-screen object culling for performance

### 📱 Recommended Specifications
- **macOS**: 10.14 or later
- **Memory**: 8GB RAM minimum
- **GPU**: Metal-compatible GPU required
- **Storage**: 500MB+ available space
- **Display**: 1920x1080 or higher resolution

## Troubleshooting

### ❗ Common Issues

**Q: Game won't start**
A: Ensure Flutter GPU experimental features are enabled and you're running on a supported macOS version.

**Q: 3D models not displaying**
A: Check that assets are properly loaded and shaders are compiled correctly. Try running with `--verbose` flag for detailed logs.

**Q: Poor performance**
A: Run in release mode (`--release`) and disable debug information. Ensure your GPU supports Metal.

**Q: Controls not responding**
A: Make sure the game window is active and focused. Check that keyboard input is properly captured.

**Q: Shader compilation errors**
A: Verify that shader bundles are present in `assets/shaderbundles/` and properly referenced in `pubspec.yaml`.

## Game Mechanics Deep Dive

### 🎮 Turn-Based Combat System
The game uses a sophisticated 5-phase turn system:
1. **Player Movement**: Character movement and position updates
2. **Enemy AI**: Enemy movement and positioning
3. **Combat Resolution**: Attack calculations and damage application
4. **Ally Actions**: Ally movement and combat assistance
5. **Effects Processing**: Status effects, cleanup, and state updates

### 🍬 Candy Effects System
Candy items provide various strategic benefits:
- **Health Restoration**: Immediate HP recovery
- **Ability Boosts**: Temporary combat strength increases
- **Special Powers**: Wall vision, enemy freezing, damage reduction
- **Ally Enhancement**: Boost ally combat effectiveness
- **Conversion Tools**: Make enemies more receptive to becoming allies

### 🏰 World Generation
The procedural world generation creates:
- **Room-Based Layout**: 50+ interconnected rooms
- **Corridor System**: Narrow 1-tile corridors for strategic movement
- **Guaranteed Pathfinding**: A* algorithm ensures solvable paths
- **Obstacle Placement**: Strategic barriers that don't block critical paths
- **Candy Distribution**: 150 candy items placed throughout the world

## Contributing

Contributions to this project are welcome:

1. **Issue Reporting**: Report bugs and suggest improvements on GitHub
2. **Pull Requests**: Submit new features and fixes
3. **Testing**: Add tests for better coverage
4. **Documentation**: Improve explanations and examples

### Development Guidelines
- Follow Dart/Flutter code style conventions
- Add tests for new features
- Update documentation for API changes
- Use meaningful commit messages

## License

MIT

## Credits & Acknowledgments

- **Flutter GPU**: Experimental 3D rendering capabilities
- **3D Models**: Character and environment assets by [Kenny](https://kenney.nl)
- **Textures**: High-quality texture files for immersive graphics

---

## Support

For questions and support:
- **GitHub Issues**: Bug reports and feature requests
- **Documentation**: This README and additional documentation
- **Community**: Flutter GPU community discussions

**Enjoy your spooky adventure! 🎮✨**
