import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';
import 'package:flutter/services.dart' show rootBundle;

class ObjFace {
  final List<int> vertexIndices;
  final List<int>? textureIndices;
  final List<int>? normalIndices;

  ObjFace({
    required this.vertexIndices,
    this.textureIndices,
    this.normalIndices,
  });
}

class ObjMaterial {
  final String name;
  Vector3 ambientColor;
  Vector3 diffuseColor;
  Vector3 specularColor;
  double opacity;
  double shininess;
  String? diffuseMap;
  String? normalMap;
  String? specularMap;
  String? ambientMap;

  ObjMaterial({
    required this.name,
    Vector3? ambientColor,
    Vector3? diffuseColor,
    Vector3? specularColor,
    this.opacity = 1.0,
    this.shininess = 1.0,
    this.diffuseMap,
    this.normalMap,
    this.specularMap,
    this.ambientMap,
  }) : ambientColor = ambientColor ?? Vector3(0.2, 0.2, 0.2),
       diffuseColor = diffuseColor ?? Vector3(0.8, 0.8, 0.8),
       specularColor = specularColor ?? Vector3(0.0, 0.0, 0.0);
}

class ObjModel {
  final List<Vector3> vertices;
  final List<Vector3> normals;
  final List<Vector2> textureCoords;
  final List<ObjFace> faces;
  final Map<String, ObjMaterial> materials;
  final Map<ObjFace, String> faceMaterials;

  ObjModel({
    required this.vertices,
    required this.normals,
    required this.textureCoords,
    required this.faces,
    required this.materials,
    required this.faceMaterials,
  });

  Float32List toVertexBuffer() {
    final List<double> buffer = [];

    for (final face in faces) {
      final material = faceMaterials[face] != null
          ? materials[faceMaterials[face]]
          : null;

      final color = (material != null && material.diffuseMap != null)
          ? Vector3(1.0, 1.0, 1.0)
          : (material?.diffuseColor ?? Vector3(0.8, 0.8, 0.8));

      if (face.vertexIndices.length == 3) {
        _addTriangle(buffer, face, 0, 1, 2, color);
      } else if (face.vertexIndices.length == 4) {
        _addTriangle(buffer, face, 0, 1, 2, color);
        _addTriangle(buffer, face, 0, 2, 3, color);
      } else if (face.vertexIndices.length > 4) {
        for (int i = 1; i < face.vertexIndices.length - 1; i++) {
          _addTriangle(buffer, face, 0, i, i + 1, color);
        }
      }
    }

    return Float32List.fromList(buffer);
  }

  void _addTriangle(
    List<double> buffer,
    ObjFace face,
    int i1,
    int i2,
    int i3,
    Vector3 color,
  ) {
    _addVertex(buffer, face, i1, color);
    _addVertex(buffer, face, i2, color);
    _addVertex(buffer, face, i3, color);
  }

  void _addVertex(List<double> buffer, ObjFace face, int index, Vector3 color) {
    final vIdx = face.vertexIndices[index] - 1;
    final vertex = vertices[vIdx];

    buffer.add(vertex.x);
    buffer.add(vertex.y);
    buffer.add(vertex.z);

    if (face.normalIndices != null && face.normalIndices!.length > index) {
      final nIdx = face.normalIndices![index] - 1;
      if (nIdx >= 0 && nIdx < normals.length) {
        final normal = normals[nIdx];
        buffer.add(normal.x);
        buffer.add(normal.y);
        buffer.add(normal.z);
      } else {
        buffer.addAll([0.0, 1.0, 0.0]);
      }
    } else {
      final faceNormal = _calculateFaceNormal(
        vertices[face.vertexIndices[0] - 1],
        vertices[face.vertexIndices[1] - 1],
        vertices[face.vertexIndices[2] - 1],
      );
      buffer.add(faceNormal.x);
      buffer.add(faceNormal.y);
      buffer.add(faceNormal.z);
    }

    buffer.add(color.x);
    buffer.add(color.y);
    buffer.add(color.z);

    if (face.textureIndices != null && face.textureIndices!.length > index) {
      final tIdx = face.textureIndices![index] - 1;
      if (tIdx >= 0 && tIdx < textureCoords.length) {
        final texCoord = textureCoords[tIdx];
        buffer.add(texCoord.x);
        buffer.add(1.0 - texCoord.y);
      } else {
        buffer.addAll([0.0, 0.0]);
      }
    } else {
      buffer.addAll([0.0, 0.0]);
    }
  }

  Vector3 _calculateFaceNormal(Vector3 v1, Vector3 v2, Vector3 v3) {
    final edge1 = v2 - v1;
    final edge2 = v3 - v1;
    return edge1.cross(edge2).normalized();
  }

  int get vertexCount {
    int count = 0;
    for (final face in faces) {
      if (face.vertexIndices.length == 3) {
        count += 3;
      } else if (face.vertexIndices.length == 4) {
        count += 6;
      } else {
        count += (face.vertexIndices.length - 2) * 3;
      }
    }
    return count;
  }
}

class ObjParser {
  static Future<ObjModel> loadFromAsset(String path) async {
    final objContent = await rootBundle.loadString(path);
    final objModel = parseObj(objContent);

    final mtlPath = path.replaceAll('.obj', '.mtl');
    try {
      final mtlContent = await rootBundle.loadString(mtlPath);
      final materials = parseMtl(mtlContent);
      return ObjModel(
        vertices: objModel.vertices,
        normals: objModel.normals,
        textureCoords: objModel.textureCoords,
        faces: objModel.faces,
        materials: materials,
        faceMaterials: objModel.faceMaterials,
      );
    } catch (e) {
      return objModel;
    }
  }

  static ObjModel parseObj(String content) {
    final vertices = <Vector3>[];
    final normals = <Vector3>[];
    final textureCoords = <Vector2>[];
    final faces = <ObjFace>[];
    final materials = <String, ObjMaterial>{};
    final faceMaterials = <ObjFace, String>{};

    String? currentMaterial;

    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;

      switch (parts[0]) {
        case 'v':
          if (parts.length >= 4) {
            vertices.add(
              Vector3(
                double.parse(parts[1]),
                double.parse(parts[2]),
                double.parse(parts[3]),
              ),
            );
          }
          break;

        case 'vn':
          if (parts.length >= 4) {
            normals.add(
              Vector3(
                double.parse(parts[1]),
                double.parse(parts[2]),
                double.parse(parts[3]),
              ).normalized(),
            );
          }
          break;

        case 'vt':
          if (parts.length >= 3) {
            textureCoords.add(
              Vector2(double.parse(parts[1]), double.parse(parts[2])),
            );
          }
          break;

        case 'f':
          final face = _parseFace(parts.sublist(1));
          if (face != null) {
            faces.add(face);
            if (currentMaterial != null) {
              faceMaterials[face] = currentMaterial;
            }
          }
          break;

        case 'usemtl':
          if (parts.length >= 2) {
            currentMaterial = parts[1];
          }
          break;
      }
    }

    return ObjModel(
      vertices: vertices,
      normals: normals,
      textureCoords: textureCoords,
      faces: faces,
      materials: materials,
      faceMaterials: faceMaterials,
    );
  }

  static ObjFace? _parseFace(List<String> vertexSpecs) {
    if (vertexSpecs.isEmpty) return null;

    final vertexIndices = <int>[];
    final textureIndices = <int>[];
    final normalIndices = <int>[];

    for (final spec in vertexSpecs) {
      final indices = spec.split('/');

      if (indices.isNotEmpty && indices[0].isNotEmpty) {
        vertexIndices.add(int.parse(indices[0]));
      }

      if (indices.length > 1 && indices[1].isNotEmpty) {
        textureIndices.add(int.parse(indices[1]));
      }

      if (indices.length > 2 && indices[2].isNotEmpty) {
        normalIndices.add(int.parse(indices[2]));
      }
    }

    if (vertexIndices.isEmpty) return null;

    return ObjFace(
      vertexIndices: vertexIndices,
      textureIndices: textureIndices.isNotEmpty ? textureIndices : null,
      normalIndices: normalIndices.isNotEmpty ? normalIndices : null,
    );
  }

  static Map<String, ObjMaterial> parseMtl(String content) {
    final materials = <String, ObjMaterial>{};
    ObjMaterial? currentMaterial;

    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;

      switch (parts[0]) {
        case 'newmtl':
          if (parts.length >= 2) {
            if (currentMaterial != null) {
              materials[currentMaterial.name] = currentMaterial;
            }
            currentMaterial = ObjMaterial(name: parts[1]);
          }
          break;

        case 'Ka':
          if (currentMaterial != null && parts.length >= 4) {
            currentMaterial.ambientColor = Vector3(
              double.parse(parts[1]),
              double.parse(parts[2]),
              double.parse(parts[3]),
            );
          }
          break;

        case 'Kd':
          if (currentMaterial != null && parts.length >= 4) {
            currentMaterial.diffuseColor = Vector3(
              double.parse(parts[1]),
              double.parse(parts[2]),
              double.parse(parts[3]),
            );
          }
          break;

        case 'Ks':
          if (currentMaterial != null && parts.length >= 4) {
            currentMaterial.specularColor = Vector3(
              double.parse(parts[1]),
              double.parse(parts[2]),
              double.parse(parts[3]),
            );
          }
          break;

        case 'd':
        case 'Tr':
          if (currentMaterial != null && parts.length >= 2) {
            currentMaterial.opacity = double.parse(parts[1]);
          }
          break;

        case 'Ns':
          if (currentMaterial != null && parts.length >= 2) {
            currentMaterial.shininess = double.parse(parts[1]);
          }
          break;

        case 'map_Kd':
          if (currentMaterial != null && parts.length >= 2) {
            String texturePath = parts.sublist(1).join(' ');
            currentMaterial.diffuseMap = texturePath;
          }
          break;

        case 'map_Ka':
          if (currentMaterial != null && parts.length >= 2) {
            currentMaterial.ambientMap = parts.sublist(1).join(' ');
          }
          break;

        case 'map_Ks':
          if (currentMaterial != null && parts.length >= 2) {
            currentMaterial.specularMap = parts.sublist(1).join(' ');
          }
          break;

        case 'map_bump':
        case 'bump':
        case 'map_Bump':
          if (currentMaterial != null && parts.length >= 2) {
            currentMaterial.normalMap = parts.sublist(1).join(' ');
          }
          break;
      }
    }

    if (currentMaterial != null) {
      materials[currentMaterial.name] = currentMaterial;
    }

    return materials;
  }
}
