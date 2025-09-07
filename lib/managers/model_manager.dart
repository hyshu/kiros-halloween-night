import 'dart:async';
import '../models/model_3d.dart';

/// Singleton manager for caching and reusing 3D models
class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  final Map<String, Model3D> _modelCache = {};
  final Map<String, Future<Model3D>> _loadingModels = {};

  /// Loads a model with caching. Returns cached model if already loaded.
  Future<Model3D> loadModel(String name, String path) async {
    // Return cached model if available
    if (_modelCache.containsKey(path)) {
      return _modelCache[path]!;
    }

    // If already loading, wait for existing load operation
    if (_loadingModels.containsKey(path)) {
      return await _loadingModels[path]!;
    }

    // Start loading the model
    final loadingFuture = Model3D.loadFromAsset(name, path);
    _loadingModels[path] = loadingFuture;

    try {
      final model = await loadingFuture;
      _modelCache[path] = model;
      return model;
    } finally {
      _loadingModels.remove(path);
    }
  }

  /// Creates a new instance of a cached model (for positioning)
  ModelInstance createInstance(Model3D model) {
    return ModelInstance(model: model);
  }

  /// Preloads commonly used models to improve startup performance
  Future<void> preloadCommonModels() async {
    final commonModels = [
      ('brick-wall', 'assets/graveyard/brick-wall.obj'),
      ('grave', 'assets/graveyard/gravestone-flat.obj'),
      ('tree', 'assets/graveyard/pine.obj'),
      ('zombie', 'assets/graveyard/character-zombie.obj'),
      ('skeleton', 'assets/graveyard/character-skeleton.obj'),
      ('ghost', 'assets/graveyard/character-ghost.obj'),
      ('candy-apple', 'assets/foods/apple.obj'),
      ('candy-chocolate', 'assets/foods/chocolate.obj'),
    ];

    await Future.wait(
      commonModels.map((entry) => loadModel(entry.$1, entry.$2)),
    );
  }

  /// Clears the model cache (useful for testing)
  void clearCache() {
    _modelCache.clear();
  }

  /// Returns cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_models': _modelCache.length,
      'loading_models': _loadingModels.length,
      'cached_paths': _modelCache.keys.toList(),
    };
  }
}