import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

class TextureManager {
  static final TextureManager _instance = TextureManager._internal();
  factory TextureManager() => _instance;
  TextureManager._internal();

  final Map<String, gpu.Texture> _textureCache = {};

  Future<gpu.Texture?> loadTexture(String path) async {
    if (_textureCache.containsKey(path)) {
      return _textureCache[path];
    }

    try {
      final assetPath = path;
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        Uint8List.view(data.buffer),
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        return null;
      }

      final texture = gpu.gpuContext.createTexture(
        gpu.StorageMode.hostVisible,
        image.width,
        image.height,
        format: gpu.PixelFormat.r8g8b8a8UNormInt,
        enableShaderReadUsage: true,
        enableShaderWriteUsage: false,
        enableRenderTargetUsage: false,
        coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture,
      );

      texture.overwrite(byteData);

      _textureCache[path] = texture;
      return texture;
    } catch (e) {
      debugPrint('TextureManager: Failed to load texture $path: $e');
      return null;
    }
  }

  gpu.Texture? createSolidColorTexture(double r, double g, double b, double a) {
    final key = 'solid_${r}_${g}_${b}_$a';
    if (_textureCache.containsKey(key)) {
      return _textureCache[key];
    }

    final byteData = ByteData(4);
    byteData.setUint8(0, (r * 255).toInt());
    byteData.setUint8(1, (g * 255).toInt());
    byteData.setUint8(2, (b * 255).toInt());
    byteData.setUint8(3, (a * 255).toInt());

    final texture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      1,
      1,
      format: gpu.PixelFormat.r8g8b8a8UNormInt,
      enableShaderReadUsage: true,
      enableShaderWriteUsage: false,
      enableRenderTargetUsage: false,
      coordinateSystem: gpu.TextureCoordinateSystem.renderToTexture,
    );

    texture.overwrite(byteData);
    _textureCache[key] = texture;
    return texture;
  }

  void clearCache() {
    _textureCache.clear();
  }
}
