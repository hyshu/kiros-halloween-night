import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_math/vector_math_64.dart' hide Vector4;
import 'package:vector_math/vector_math.dart' as vm;

import '../core/shaders.dart';
import '../scene/scene_manager.dart';
import '../managers/texture_manager.dart';

class MultiModelRenderer extends material.StatefulWidget {
  final material.Color backgroundColor;
  final SceneManager sceneManager;

  const MultiModelRenderer({
    super.key,
    this.backgroundColor = const material.Color(0xFF000000),
    required this.sceneManager,
  });

  @override
  material.State<MultiModelRenderer> createState() =>
      _MultiModelRendererState();
}

class _MultiModelRendererState extends material.State<MultiModelRenderer> {
  double _rotationX = 0.2;
  double _rotationY = 0.0;
  double _cameraDistance = 10.0;
  Vector3 _cameraPosition = Vector3(0, 5, 10);
  final Vector3 _cameraTarget = Vector3.zero();

  double _baseScale = 1.0;
  material.Offset? _lastFocalPoint;

  @override
  void initState() {
    super.initState();
    widget.sceneManager.addListener(_onSceneUpdate);
  }

  @override
  void dispose() {
    widget.sceneManager.removeListener(_onSceneUpdate);
    super.dispose();
  }

  void _onSceneUpdate() {
    setState(() {});
  }

  @override
  material.Widget build(material.BuildContext context) {
    return material.GestureDetector(
      onScaleStart: (details) {
        _baseScale = _cameraDistance;
        _lastFocalPoint = details.localFocalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.scale != 1.0) {
            _cameraDistance = (_baseScale / details.scale).clamp(2.0, 50.0);
          }

          if (_lastFocalPoint != null) {
            final delta = details.localFocalPoint - _lastFocalPoint!;
            _rotationX += delta.dy * 0.01;
            _rotationY += delta.dx * 0.01;
            _rotationX = _rotationX.clamp(-1.5, 1.5);
          }

          _updateCameraPosition();
          _lastFocalPoint = details.localFocalPoint;
        });
      },
      onScaleEnd: (details) {
        _lastFocalPoint = null;
      },
      child: material.AnimatedBuilder(
        animation: widget.sceneManager,
        builder: (context, child) {
          return material.CustomPaint(
            painter: MultiModelPainter(
              objects: widget.sceneManager.objects,
              cameraPosition: _cameraPosition,
              cameraTarget: _cameraTarget,
              backgroundColor: widget.backgroundColor,
              devicePixelRatio: material.View.of(context).devicePixelRatio,
            ),
            size: material.Size.infinite,
          );
        },
      ),
    );
  }

  void _updateCameraPosition() {
    final x = _cameraDistance * math.sin(_rotationY) * math.cos(_rotationX);
    final y = _cameraDistance * math.sin(_rotationX);
    final z = _cameraDistance * math.cos(_rotationY) * math.cos(_rotationX);
    _cameraPosition = Vector3(x, y, z);
  }
}

class MultiModelPainter extends material.CustomPainter {
  final List<SceneObject> objects;
  final Vector3 cameraPosition;
  final Vector3 cameraTarget;
  final material.Color backgroundColor;
  final double devicePixelRatio;

  MultiModelPainter({
    required this.objects,
    required this.cameraPosition,
    required this.cameraTarget,
    required this.backgroundColor,
    required this.devicePixelRatio,
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

    final vert = shaderLibrary['BoxVertex']!;
    final frag = shaderLibrary['BoxFragment']!;

    for (final object in objects) {
      if (object.model != null && !object.isLoading) {
        final mvpMatrix = vpMatrix * object.modelMatrix;
        _drawModel(renderPass, vert, frag, mvpMatrix, object);
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

  void _drawModel(
    gpu.RenderPass renderPass,
    gpu.Shader vert,
    gpu.Shader frag,
    Matrix4 mvpMatrix,
    SceneObject object,
  ) {
    if (object.model == null) return;

    final uniformData = Float32List(32);
    uniformData.setRange(0, 16, mvpMatrix.storage);
    uniformData.setRange(16, 32, object.modelMatrix.storage);
    final uniformByteData = ByteData.sublistView(uniformData);

    final pipeline = gpu.gpuContext.createRenderPipeline(vert, frag);
    renderPass.bindPipeline(pipeline);

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

    gpu.Texture? diffuseTexture;
    final textureManager = TextureManager();

    if (object.model!.materialTextures.isNotEmpty) {
      final firstMaterial = object.model!.materialTextures.values.first;
      diffuseTexture = firstMaterial.diffuseTexture;
    }

    diffuseTexture ??= textureManager.createSolidColorTexture(
      1.0,
      1.0,
      1.0,
      1.0,
    );

    if (diffuseTexture != null) {
      final samplerOptions = gpu.SamplerOptions(
        minFilter: gpu.MinMagFilter.linear,
        magFilter: gpu.MinMagFilter.linear,
        mipFilter: gpu.MipFilter.linear,
        widthAddressMode: gpu.SamplerAddressMode.repeat,
        heightAddressMode: gpu.SamplerAddressMode.repeat,
      );

      renderPass.bindTexture(
        frag.getUniformSlot('diffuseTexture'),
        diffuseTexture,
        sampler: samplerOptions,
      );
    } else {
      debugPrint('MultiModelRenderer: ERROR - No texture to bind!');
    }

    if (gpu.gpuContext.createDeviceBufferWithCopy(
          ByteData.sublistView(object.model!.vertexBuffer),
        )
        case gpu.DeviceBuffer verticesBuffer) {
      final verticesView = gpu.BufferView(
        verticesBuffer,
        offsetInBytes: 0,
        lengthInBytes: verticesBuffer.sizeInBytes,
      );

      renderPass.setCullMode(gpu.CullMode.frontFace);
      renderPass.setWindingOrder(gpu.WindingOrder.clockwise);
      renderPass.setDepthWriteEnable(true);
      renderPass.setDepthCompareOperation(gpu.CompareFunction.less);

      renderPass.bindVertexBuffer(verticesView, object.model!.vertexCount);
      renderPass.draw();
    }
  }

  @override
  bool shouldRepaint(covariant MultiModelPainter oldDelegate) {
    return oldDelegate.objects != objects ||
        oldDelegate.cameraPosition != cameraPosition ||
        oldDelegate.cameraTarget != cameraTarget ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
