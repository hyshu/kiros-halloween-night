import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

import '../parsers/obj_parser.dart';
import '../managers/texture_manager.dart';

class MaterialTextures {
  gpu.Texture? diffuseTexture;
  gpu.Texture? normalTexture;
  gpu.Texture? specularTexture;
  gpu.Texture? ambientTexture;

  MaterialTextures({
    this.diffuseTexture,
    this.normalTexture,
    this.specularTexture,
    this.ambientTexture,
  });
}

class Model3D {
  final String name;
  final ObjModel objModel;
  final Float32List vertexBuffer;
  final int vertexCount;
  final Map<String, MaterialTextures> materialTextures = {};

  Vector3 position;
  Vector3 rotation;
  Vector3 scale;

  Model3D({
    required this.name,
    required this.objModel,
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
  }) : vertexBuffer = objModel.toVertexBuffer(),
       vertexCount = objModel.vertexCount,
       position = position ?? Vector3.zero(),
       rotation = rotation ?? Vector3.zero(),
       scale = scale ?? Vector3.all(1.0);

  static Future<Model3D> loadFromAsset(String name, String path) async {
    final objModel = await ObjParser.loadFromAsset(path);
    final model = Model3D(name: name, objModel: objModel);

    final textureManager = TextureManager();
    final basePath = path.substring(0, path.lastIndexOf('/') + 1);

    for (final material in objModel.materials.values) {
      final textures = MaterialTextures();

      if (material.diffuseMap != null) {
        String texturePath = '$basePath${material.diffuseMap!}';
        textures.diffuseTexture = await textureManager.loadTexture(texturePath);
      }

      if (material.normalMap != null) {
        String texturePath = '$basePath${material.normalMap!}';
        textures.normalTexture = await textureManager.loadTexture(texturePath);
      }

      if (material.specularMap != null) {
        String texturePath = '$basePath${material.specularMap!}';
        textures.specularTexture = await textureManager.loadTexture(
          texturePath,
        );
      }

      if (material.ambientMap != null) {
        String texturePath = '$basePath${material.ambientMap!}';
        textures.ambientTexture = await textureManager.loadTexture(texturePath);
      }

      textures.diffuseTexture ??= textureManager.createSolidColorTexture(
        material.diffuseColor.x,
        material.diffuseColor.y,
        material.diffuseColor.z,
        material.opacity,
      );

      model.materialTextures[material.name] = textures;
    }

    if (model.materialTextures.isEmpty) {
      final defaultTexture = textureManager.createSolidColorTexture(
        0.8,
        0.8,
        0.8,
        1.0,
      );
      model.materialTextures['default'] = MaterialTextures(
        diffuseTexture: defaultTexture,
      );
    }

    return model;
  }

  Matrix4 get modelMatrix {
    final matrix = Matrix4.identity();

    matrix.translateByVector3(position);

    matrix.rotateX(rotation.x);
    matrix.rotateY(rotation.y);
    matrix.rotateZ(rotation.z);

    matrix.scaleByVector3(scale);

    return matrix;
  }

  void setPosition(double x, double y, double z) {
    position.setValues(x, y, z);
  }

  void setRotation(double x, double y, double z) {
    rotation.setValues(x, y, z);
  }

  void setScale(double x, double y, double z) {
    scale.setValues(x, y, z);
  }

  void setUniformScale(double s) {
    scale.setValues(s, s, s);
  }
}

class ModelInstance {
  final Model3D model;

  Vector3 position;
  Vector3 rotation;
  Vector3 scale;
  bool visible;

  ModelInstance({
    required this.model,
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
    this.visible = true,
  }) : position = position ?? Vector3.zero(),
       rotation = rotation ?? Vector3.zero(),
       scale = scale ?? Vector3.all(1.0);

  Matrix4 get modelMatrix {
    final matrix = Matrix4.identity();

    matrix.translateByVector3(position);

    matrix.rotateX(rotation.x);
    matrix.rotateY(rotation.y);
    matrix.rotateZ(rotation.z);

    matrix.scaleByVector3(scale);

    return matrix;
  }

  Float32List get vertexBuffer => model.vertexBuffer;
  int get vertexCount => model.vertexCount;

  void setPosition(double x, double y, double z) {
    position.setValues(x, y, z);
  }

  void setRotation(double x, double y, double z) {
    rotation.setValues(x, y, z);
  }

  void setScale(double x, double y, double z) {
    scale.setValues(x, y, z);
  }

  void setUniformScale(double s) {
    scale.setValues(s, s, s);
  }
}
