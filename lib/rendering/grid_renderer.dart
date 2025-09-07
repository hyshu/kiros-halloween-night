import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart' as material;
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_math/vector_math_64.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../core/shaders.dart';
import '../scene/grid_scene_manager.dart';
import '../models/model_3d.dart';
import '../core/tile_map.dart';

class GridRenderer extends material.StatefulWidget {
  final material.Color backgroundColor;
  final GridSceneManager sceneManager;

  const GridRenderer({
    super.key,
    this.backgroundColor = const material.Color(0xFF000000),
    required this.sceneManager,
  });

  @override
  material.State<GridRenderer> createState() => _GridRendererState();
}

class _GridRendererState extends material.State<GridRenderer> {
  double _rotationX = 0.3;
  double _rotationY = 0.0;
  double _cameraDistance = 8.0;
  Vector3 _cameraPosition = Vector3(10, 15, 20);
  Vector3 _cameraTarget = Vector3(10, 0, 10);

  double _baseScale = 1.0;
  material.Offset? _lastFocalPoint;

  // Pan controls for large world navigation
  Vector3 _panOffset = Vector3.zero();
  material.Offset? _lastPanPoint;

  @override
  void initState() {
    super.initState();
    widget.sceneManager.addListener(_onSceneUpdate);
    _initializeCameraForWorld();
    _updateCameraPosition();
  }

  void _initializeCameraForWorld() {
    if (widget.sceneManager.tileMap != null) {
      _cameraTarget = widget.sceneManager.cameraTarget;
      _cameraDistance = 12.0;
    }
  }

  @override
  void dispose() {
    widget.sceneManager.removeListener(_onSceneUpdate);
    super.dispose();
  }

  void _onSceneUpdate() {
    setState(() {
      final newTarget = widget.sceneManager.cameraTarget;
      final targetDifference = (newTarget - _cameraTarget).length;
      if (targetDifference > 2.0) {
        _panOffset = Vector3.zero();
      }

      _cameraTarget = newTarget + _panOffset;
      _updateCameraPosition();
    });
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.GestureDetector(
      onScaleStart: (details) {
        _baseScale = _cameraDistance;
        _lastFocalPoint = details.localFocalPoint;
        _lastPanPoint = details.localFocalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.scale != 1.0) {
            final minDistance = widget.sceneManager.tileMap != null ? 5.0 : 3.0;
            final maxDistance = widget.sceneManager.tileMap != null
                ? 25.0
                : 15.0;
            _cameraDistance = (_baseScale / details.scale).clamp(
              minDistance,
              maxDistance,
            );
          }

          if (_lastFocalPoint != null && _lastPanPoint != null) {
            final delta = details.localFocalPoint - _lastFocalPoint!;

            if (details.pointerCount == 1) {
              final panSensitivity = _cameraDistance * 0.005;
              final panDelta =
                  (details.localFocalPoint - _lastPanPoint!) * panSensitivity;

              final rightVector = Vector3(
                math.cos(_rotationY),
                0,
                -math.sin(_rotationY),
              );
              final forwardVector = Vector3(
                math.sin(_rotationY),
                0,
                math.cos(_rotationY),
              );

              final newPanOffset =
                  _panOffset +
                  rightVector * panDelta.dx +
                  forwardVector * panDelta.dy;

              final maxPanDistance = 20.0;
              if (newPanOffset.length <= maxPanDistance) {
                _panOffset = newPanOffset;
                _cameraTarget = widget.sceneManager.cameraTarget + _panOffset;
              }

              _lastPanPoint = details.localFocalPoint;
            } else {
              _rotationX += delta.dy * 0.01;
              _rotationY += delta.dx * 0.01;
              _rotationX = _rotationX.clamp(-1.5, 1.5);
            }
          }

          _updateCameraPosition();
          _lastFocalPoint = details.localFocalPoint;
        });
      },
      onScaleEnd: (details) {
        _lastFocalPoint = null;
        _lastPanPoint = null;
      },
      child: material.Stack(
        children: [
          material.AnimatedBuilder(
            animation: widget.sceneManager,
            builder: (context, _) {
              return material.CustomPaint(
                painter: GPUPainter(
                  backgroundColor: widget.backgroundColor,
                  objects: widget.sceneManager.allObjects,
                  cameraPosition: _cameraPosition,
                  cameraTarget: _cameraTarget,
                  devicePixelRatio: material.MediaQuery.of(
                    context,
                  ).devicePixelRatio,
                  tileMap: widget.sceneManager.tileMap,
                ),
                child: const material.SizedBox.expand(),
              );
            },
          ),
          if (widget.sceneManager.tileMap != null)
            material.Positioned(
              top: 20,
              left: 20,
              child: material.Container(
                padding: const material.EdgeInsets.all(8),
                decoration: material.BoxDecoration(
                  color: material.Colors.black54,
                  borderRadius: material.BorderRadius.circular(8),
                ),
                child: material.Column(
                  crossAxisAlignment: material.CrossAxisAlignment.start,
                  mainAxisSize: material.MainAxisSize.min,
                  children: [
                    material.Text(
                      'World: ${widget.sceneManager.tileMap!.dimensions.$1}x${widget.sceneManager.tileMap!.dimensions.$2}',
                      style: const material.TextStyle(
                        color: material.Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    material.Text(
                      'Camera: (${(_cameraTarget.x / 2.0).round()}, ${(_cameraTarget.z / 2.0).round()})',
                      style: const material.TextStyle(
                        color: material.Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    material.Text(
                      'Objects: ${widget.sceneManager.allObjects.length}',
                      style: const material.TextStyle(
                        color: material.Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _updateCameraPosition() {
    final distance = _cameraDistance;
    _cameraPosition = Vector3(
      _cameraTarget.x + math.sin(_rotationY) * math.cos(_rotationX) * distance,
      _cameraTarget.y + math.sin(_rotationX) * distance,
      _cameraTarget.z + math.cos(_rotationY) * math.cos(_rotationX) * distance,
    );
  }
}

class GPUPainter extends material.CustomPainter {
  final material.Color backgroundColor;
  final List<GridObject> objects;
  final Vector3 cameraPosition;
  final Vector3 cameraTarget;
  final double devicePixelRatio;
  final TileMap? tileMap;

  GPUPainter({
    required this.backgroundColor,
    required this.objects,
    required this.cameraPosition,
    required this.cameraTarget,
    required this.devicePixelRatio,
    this.tileMap,
  });

  @override
  void paint(material.Canvas canvas, material.Size size) {
    final physicalWidth = (size.width * devicePixelRatio).toInt();
    final physicalHeight = (size.height * devicePixelRatio).toInt();

    final texture = gpu.gpuContext.createTexture(
      gpu.StorageMode.devicePrivate,
      physicalWidth,
      physicalHeight,
    );

    final depthTexture = gpu.gpuContext.createTexture(
      gpu.StorageMode.devicePrivate,
      physicalWidth,
      physicalHeight,
      format: gpu.PixelFormat.d32FloatS8UInt,
      enableRenderTargetUsage: true,
    );

    final renderTarget = gpu.RenderTarget(
      colorAttachments: [
        gpu.ColorAttachment(
          texture: texture,
          clearValue: vm.Vector4(
            backgroundColor.r,
            backgroundColor.g,
            backgroundColor.b,
            backgroundColor.a,
          ),
        ),
      ],
      depthStencilAttachment: gpu.DepthStencilAttachment(
        texture: depthTexture,
        depthClearValue: 1.0,
        depthLoadAction: gpu.LoadAction.clear,
        depthStoreAction: gpu.StoreAction.dontCare,
      ),
    );

    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    final renderPass = commandBuffer.createRenderPass(renderTarget);

    final vpMatrix = _createViewProjectionMatrix(size);

    _renderGridFloor(renderPass, vpMatrix);

    final vert = shaderLibrary['BoxVertex'];
    final frag = shaderLibrary['BoxFragment'];

    if (vert != null && frag != null) {
      for (final object in objects) {
        if (object.model != null) {
          final mvpMatrix = vpMatrix * object.modelMatrix;
          _drawModel(renderPass, vert, frag, mvpMatrix, object.model!);
        }
      }
    }

    commandBuffer.submit();

    final resultImage = texture.asImage();
    canvas.drawImageRect(
      resultImage,
      material.Rect.fromLTWH(
        0,
        0,
        physicalWidth.toDouble(),
        physicalHeight.toDouble(),
      ),
      material.Rect.fromLTWH(0, 0, size.width, size.height),
      material.Paint(),
    );
  }

  Matrix4 _createViewProjectionMatrix(material.Size size) {
    final aspectRatio = size.width / size.height;
    final projectionMatrix = makePerspectiveMatrix(
      radians(45.0),
      aspectRatio,
      0.1,
      100.0,
    );

    final viewMatrix = Matrix4.identity();
    setViewMatrix(
      viewMatrix,
      cameraPosition,
      cameraTarget,
      Vector3(0.0, 1.0, 0.0),
    );

    return projectionMatrix * viewMatrix;
  }

  void _renderGridFloor(gpu.RenderPass renderPass, Matrix4 vpMatrix) {
    final vert = shaderLibrary['BoxVertex'];
    final frag = shaderLibrary['BoxFragment'];
    if (vert == null || frag == null) return;

    final pipeline = gpu.gpuContext.createRenderPipeline(vert, frag);
    renderPass.bindPipeline(pipeline);

    renderPass.setCullMode(gpu.CullMode.none);
    renderPass.setWindingOrder(gpu.WindingOrder.clockwise);
    renderPass.setDepthWriteEnable(true);
    renderPass.setDepthCompareOperation(gpu.CompareFunction.less);

    final uniformData = Float32List(16);
    uniformData.setRange(0, 16, vpMatrix.storage);
    final uniformByteData = ByteData.sublistView(uniformData);

    if (gpu.gpuContext.createDeviceBufferWithCopy(uniformByteData)
        case gpu.DeviceBuffer uniformBuffer) {
      final uniformSlot = vert.getUniformSlot('Uniforms');
      final uniformView = gpu.BufferView(
        uniformBuffer,
        offsetInBytes: 0,
        lengthInBytes: uniformBuffer.sizeInBytes,
      );
      renderPass.bindUniform(uniformSlot, uniformView);
    }

    final gridVertices = _createGridVertices();
    if (gpu.gpuContext.createDeviceBufferWithCopy(
          ByteData.sublistView(gridVertices),
        )
        case gpu.DeviceBuffer vertexBuffer) {
      final verticesView = gpu.BufferView(
        vertexBuffer,
        offsetInBytes: 0,
        lengthInBytes: vertexBuffer.sizeInBytes,
      );
      renderPass.bindVertexBuffer(verticesView, 6);
    }

    final gridTexture = _createGridTexture();
    final textureSlot = frag.getUniformSlot('diffuseTexture');
    final samplerOptions = gpu.SamplerOptions(
      minFilter: gpu.MinMagFilter.linear,
      magFilter: gpu.MinMagFilter.linear,
      mipFilter: gpu.MipFilter.linear,
      widthAddressMode: gpu.SamplerAddressMode.repeat,
      heightAddressMode: gpu.SamplerAddressMode.repeat,
    );
    renderPass.bindTexture(textureSlot, gridTexture, sampler: samplerOptions);

    renderPass.draw();
  }

  void _drawModel(
    gpu.RenderPass renderPass,
    gpu.Shader vert,
    gpu.Shader frag,
    Matrix4 mvpMatrix,
    Model3D model,
  ) {
    final pipeline = gpu.gpuContext.createRenderPipeline(vert, frag);
    renderPass.bindPipeline(pipeline);

    renderPass.setCullMode(gpu.CullMode.frontFace);
    renderPass.setWindingOrder(gpu.WindingOrder.clockwise);
    renderPass.setDepthWriteEnable(true);
    renderPass.setDepthCompareOperation(gpu.CompareFunction.less);

    final uniformData = Float32List(16);
    uniformData.setRange(0, 16, mvpMatrix.storage);
    final uniformByteData = ByteData.sublistView(uniformData);

    if (gpu.gpuContext.createDeviceBufferWithCopy(uniformByteData)
        case gpu.DeviceBuffer uniformBuffer) {
      final uniformSlot = vert.getUniformSlot('Uniforms');
      final uniformView = gpu.BufferView(
        uniformBuffer,
        offsetInBytes: 0,
        lengthInBytes: uniformBuffer.sizeInBytes,
      );
      renderPass.bindUniform(uniformSlot, uniformView);
    }

    if (gpu.gpuContext.createDeviceBufferWithCopy(
          ByteData.sublistView(model.vertexBuffer),
        )
        case gpu.DeviceBuffer vertexBuffer) {
      final verticesView = gpu.BufferView(
        vertexBuffer,
        offsetInBytes: 0,
        lengthInBytes: vertexBuffer.sizeInBytes,
      );
      renderPass.bindVertexBuffer(verticesView, model.vertexCount);
    }

    gpu.Texture? diffuseTexture;
    if (model.materialTextures.isNotEmpty) {
      final firstMaterial = model.materialTextures.values.first;
      diffuseTexture = firstMaterial.diffuseTexture;
    }

    diffuseTexture ??= _createDefaultTexture();

    final textureSlot = frag.getUniformSlot('diffuseTexture');
    final samplerOptions = gpu.SamplerOptions(
      minFilter: gpu.MinMagFilter.linear,
      magFilter: gpu.MinMagFilter.linear,
      mipFilter: gpu.MipFilter.linear,
      widthAddressMode: gpu.SamplerAddressMode.repeat,
      heightAddressMode: gpu.SamplerAddressMode.repeat,
    );
    renderPass.bindTexture(
      textureSlot,
      diffuseTexture,
      sampler: samplerOptions,
    );

    renderPass.draw();
  }

  Float32List _createGridVertices() {
    double size;
    double offsetX = 0;
    double offsetZ = 0;

    if (tileMap != null) {
      size = 200.0;
      offsetX = cameraTarget.x - size / 2;
      offsetZ = cameraTarget.z - size / 2;
    } else {
      size = GridSceneManager.gridSize * 2.0;
    }

    return Float32List.fromList([
      offsetX,
      -0.01,
      offsetZ,
      0,
      1,
      0,
      0.2,
      0.2,
      0.2,
      0,
      0,
      offsetX + size,
      -0.01,
      offsetZ,
      0,
      1,
      0,
      0.2,
      0.2,
      0.2,
      1,
      0,
      offsetX + size,
      -0.01,
      offsetZ + size,
      0,
      1,
      0,
      0.2,
      0.2,
      0.2,
      1,
      1,
      offsetX,
      -0.01,
      offsetZ,
      0,
      1,
      0,
      0.2,
      0.2,
      0.2,
      0,
      0,
      offsetX + size,
      -0.01,
      offsetZ + size,
      0,
      1,
      0,
      0.2,
      0.2,
      0.2,
      1,
      1,
      offsetX,
      -0.01,
      offsetZ + size,
      0,
      1,
      0,
      0.2,
      0.2,
      0.2,
      0,
      1,
    ]);
  }

  gpu.Texture _createGridTexture() {
    const gridSize = 512;
    final data = Uint8List(gridSize * gridSize * 4);
    final random = math.Random(42);

    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final index = (y * gridSize + x) * 4;

        final noise = random.nextDouble();
        final variation = (noise * 20 - 10).round();

        int r = (80 + variation).clamp(0, 255);
        int g = (70 + variation).clamp(0, 255);
        int b = (60 + variation).clamp(0, 255);

        if (noise > 0.95) {
          r = (r * 0.9).round();
          g = (g * 1.1).round().clamp(0, 255);
          b = (b * 0.9).round();
        } else if (noise < 0.05) {
          r = (r * 0.8).round();
          g = (g * 0.8).round();
          b = (b * 0.85).round();
        }

        data[index] = r;
        data[index + 1] = g;
        data[index + 2] = b;
        data[index + 3] = 255;
      }
    }

    final texture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      gridSize,
      gridSize,
    );
    texture.overwrite(ByteData.sublistView(data));
    return texture;
  }

  gpu.Texture _createDefaultTexture() {
    final data = Uint8List(4 * 4 * 4);
    for (var i = 0; i < data.length; i += 4) {
      data[i] = 200;
      data[i + 1] = 200;
      data[i + 2] = 200;
      data[i + 3] = 255;
    }
    final texture = gpu.gpuContext.createTexture(
      gpu.StorageMode.hostVisible,
      4,
      4,
    );
    texture.overwrite(ByteData.sublistView(data));
    return texture;
  }

  @override
  bool shouldRepaint(GPUPainter oldDelegate) {
    return objects != oldDelegate.objects ||
        cameraPosition != oldDelegate.cameraPosition ||
        cameraTarget != oldDelegate.cameraTarget ||
        backgroundColor != oldDelegate.backgroundColor ||
        tileMap != oldDelegate.tileMap;
  }
}
