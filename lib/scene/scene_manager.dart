import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/model_3d.dart';

class SceneObject {
  final String id;
  final String modelPath;
  final String displayName;
  Model3D? model;
  Vector3 position;
  Vector3 rotation;
  Vector3 scale;
  bool isSelected;
  bool isLoading;

  SceneObject({
    required this.id,
    required this.modelPath,
    required this.displayName,
    this.model,
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
    this.isSelected = false,
    this.isLoading = false,
  }) : position = position ?? Vector3.zero(),
       rotation = rotation ?? Vector3.zero(),
       scale = scale ?? Vector3.all(1.0);

  Matrix4 get modelMatrix {
    return Matrix4.identity()
      ..translateByVector3(position)
      ..rotateX(rotation.x)
      ..rotateY(rotation.y)
      ..rotateZ(rotation.z)
      ..scaleByVector3(scale);
  }

  SceneObject copyWith({
    String? id,
    String? modelPath,
    String? displayName,
    Model3D? model,
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
    bool? isSelected,
    bool? isLoading,
  }) {
    return SceneObject(
      id: id ?? this.id,
      modelPath: modelPath ?? this.modelPath,
      displayName: displayName ?? this.displayName,
      model: model ?? this.model,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      isSelected: isSelected ?? this.isSelected,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SceneManager extends ChangeNotifier {
  final List<SceneObject> _objects = [];
  String? _selectedObjectId;

  List<SceneObject> get objects => List.unmodifiable(_objects);
  SceneObject? get selectedObject =>
      _selectedObjectId != null ? getObject(_selectedObjectId!) : null;

  SceneObject? getObject(String id) {
    try {
      return _objects.firstWhere((obj) => obj.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addObject({
    required String modelPath,
    required String displayName,
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newObject = SceneObject(
      id: id,
      modelPath: modelPath,
      displayName: displayName,
      position:
          position ??
          Vector3(
            (math.Random().nextDouble() - 0.5) * 2,
            0,
            (math.Random().nextDouble() - 0.5) * 2,
          ),
      rotation: rotation,
      scale: scale,
      isLoading: true,
    );

    _objects.add(newObject);
    notifyListeners();

    try {
      final model = await Model3D.loadFromAsset(displayName, modelPath);

      final index = _objects.indexWhere((obj) => obj.id == id);
      if (index != -1) {
        _objects[index] = _objects[index].copyWith(
          model: model,
          isLoading: false,
        );
        notifyListeners();
      }
    } catch (e) {
      final index = _objects.indexWhere((obj) => obj.id == id);
      if (index != -1) {
        _objects[index] = _objects[index].copyWith(isLoading: false);
        notifyListeners();
      }
      rethrow;
    }
  }

  void removeObject(String id) {
    _objects.removeWhere((obj) => obj.id == id);
    if (_selectedObjectId == id) {
      _selectedObjectId = null;
    }
    notifyListeners();
  }

  void selectObject(String? id) {
    _selectedObjectId = id;
    for (var obj in _objects) {
      obj.isSelected = obj.id == id;
    }
    notifyListeners();
  }

  void updateObject({
    required String id,
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
  }) {
    final index = _objects.indexWhere((obj) => obj.id == id);
    if (index != -1) {
      final obj = _objects[index];
      _objects[index] = obj.copyWith(
        position: position ?? obj.position,
        rotation: rotation ?? obj.rotation,
        scale: scale ?? obj.scale,
      );
      notifyListeners();
    }
  }

  static List<Map<String, String>> getAvailableModels() {
    return [
      {'path': 'assets/graveyard/altar-stone.obj', 'name': 'Altar Stone'},
      {'path': 'assets/graveyard/altar-wood.obj', 'name': 'Altar Wood'},
      {'path': 'assets/graveyard/bench-damaged.obj', 'name': 'Bench Damaged'},
      {'path': 'assets/graveyard/bench.obj', 'name': 'Bench'},
      {'path': 'assets/graveyard/border-pillar.obj', 'name': 'Border Pillar'},
      {
        'path': 'assets/graveyard/brick-wall-curve-small.obj',
        'name': 'Brick Wall Curve Small',
      },
      {
        'path': 'assets/graveyard/brick-wall-curve.obj',
        'name': 'Brick Wall Curve',
      },
      {'path': 'assets/graveyard/brick-wall-end.obj', 'name': 'Brick Wall End'},
      {'path': 'assets/graveyard/brick-wall.obj', 'name': 'Brick Wall'},
      {
        'path': 'assets/graveyard/candle-multiple.obj',
        'name': 'Candle Multiple',
      },
      {'path': 'assets/graveyard/candle.obj', 'name': 'Candle'},
      {
        'path': 'assets/graveyard/character-digger.obj',
        'name': 'Character Digger',
      },
      {
        'path': 'assets/graveyard/character-ghost.obj',
        'name': 'Character Ghost',
      },
      {
        'path': 'assets/graveyard/character-skeleton.obj',
        'name': 'Character Skeleton',
      },
      {
        'path': 'assets/graveyard/character-vampire.obj',
        'name': 'Character Vampire',
      },
      {
        'path': 'assets/graveyard/character-zombie.obj',
        'name': 'Character Zombie',
      },
      {'path': 'assets/graveyard/coffin-old.obj', 'name': 'Coffin Old'},
      {'path': 'assets/graveyard/coffin.obj', 'name': 'Coffin'},
      {'path': 'assets/graveyard/column-large.obj', 'name': 'Column Large'},
      {'path': 'assets/graveyard/cross-column.obj', 'name': 'Cross Column'},
      {'path': 'assets/graveyard/cross-wood.obj', 'name': 'Cross Wood'},
      {'path': 'assets/graveyard/cross.obj', 'name': 'Cross'},
      {'path': 'assets/graveyard/crypt-door.obj', 'name': 'Crypt Door'},
      {
        'path': 'assets/graveyard/crypt-large-roof.obj',
        'name': 'Crypt Large Roof',
      },
      {'path': 'assets/graveyard/crypt-large.obj', 'name': 'Crypt Large'},
      {
        'path': 'assets/graveyard/crypt-small-entrance-alternative.obj',
        'name': 'Crypt Small Entrance Alternative',
      },
      {
        'path': 'assets/graveyard/crypt-small-entrance.obj',
        'name': 'Crypt Small Entrance',
      },
      {
        'path': 'assets/graveyard/crypt-small-roof.obj',
        'name': 'Crypt Small Roof',
      },
      {'path': 'assets/graveyard/crypt-small.obj', 'name': 'Crypt Small'},
      {'path': 'assets/graveyard/crypt.obj', 'name': 'Crypt'},
      {'path': 'assets/graveyard/debris-wood.obj', 'name': 'Debris Wood'},
      {'path': 'assets/graveyard/debris.obj', 'name': 'Debris'},
      {'path': 'assets/graveyard/detail-bowl.obj', 'name': 'Detail Bowl'},
      {'path': 'assets/graveyard/detail-chalice.obj', 'name': 'Detail Chalice'},
      {'path': 'assets/graveyard/detail-plate.obj', 'name': 'Detail Plate'},
      {'path': 'assets/graveyard/fence-damaged.obj', 'name': 'Fence Damaged'},
      {'path': 'assets/graveyard/fence-gate.obj', 'name': 'Fence Gate'},
      {'path': 'assets/graveyard/fence.obj', 'name': 'Fence'},
      {'path': 'assets/graveyard/fire-basket.obj', 'name': 'Fire Basket'},
      {'path': 'assets/graveyard/grave-border.obj', 'name': 'Grave Border'},
      {'path': 'assets/graveyard/grave.obj', 'name': 'Grave'},
      {
        'path': 'assets/graveyard/gravestone-bevel.obj',
        'name': 'Gravestone Bevel',
      },
      {
        'path': 'assets/graveyard/gravestone-broken.obj',
        'name': 'Gravestone Broken',
      },
      {
        'path': 'assets/graveyard/gravestone-cross-large.obj',
        'name': 'Gravestone Cross Large',
      },
      {
        'path': 'assets/graveyard/gravestone-cross.obj',
        'name': 'Gravestone Cross',
      },
      {
        'path': 'assets/graveyard/gravestone-debris.obj',
        'name': 'Gravestone Debris',
      },
      {
        'path': 'assets/graveyard/gravestone-decorative.obj',
        'name': 'Gravestone Decorative',
      },
      {
        'path': 'assets/graveyard/gravestone-flat-open.obj',
        'name': 'Gravestone Flat Open',
      },
      {
        'path': 'assets/graveyard/gravestone-flat.obj',
        'name': 'Gravestone Flat',
      },
      {
        'path': 'assets/graveyard/gravestone-roof.obj',
        'name': 'Gravestone Roof',
      },
      {
        'path': 'assets/graveyard/gravestone-round.obj',
        'name': 'Gravestone Round',
      },
      {
        'path': 'assets/graveyard/gravestone-wide.obj',
        'name': 'Gravestone Wide',
      },
      {
        'path': 'assets/graveyard/hay-bale-bundled.obj',
        'name': 'Hay Bale Bundled',
      },
      {'path': 'assets/graveyard/hay-bale.obj', 'name': 'Hay Bale'},
      {'path': 'assets/graveyard/iron-fence-bar.obj', 'name': 'Iron Fence Bar'},
      {
        'path': 'assets/graveyard/iron-fence-border-column.obj',
        'name': 'Iron Fence Border Column',
      },
      {
        'path': 'assets/graveyard/iron-fence-border-curve.obj',
        'name': 'Iron Fence Border Curve',
      },
      {
        'path': 'assets/graveyard/iron-fence-border-gate.obj',
        'name': 'Iron Fence Border Gate',
      },
      {
        'path': 'assets/graveyard/iron-fence-border.obj',
        'name': 'Iron Fence Border',
      },
      {
        'path': 'assets/graveyard/iron-fence-curve.obj',
        'name': 'Iron Fence Curve',
      },
      {
        'path': 'assets/graveyard/iron-fence-damaged.obj',
        'name': 'Iron Fence Damaged',
      },
      {'path': 'assets/graveyard/iron-fence.obj', 'name': 'Iron Fence'},
      {'path': 'assets/graveyard/lantern-candle.obj', 'name': 'Lantern Candle'},
      {'path': 'assets/graveyard/lantern-glass.obj', 'name': 'Lantern Glass'},
      {'path': 'assets/graveyard/lightpost-all.obj', 'name': 'Lightpost All'},
      {
        'path': 'assets/graveyard/lightpost-double.obj',
        'name': 'Lightpost Double',
      },
      {
        'path': 'assets/graveyard/lightpost-single.obj',
        'name': 'Lightpost Single',
      },
      {'path': 'assets/graveyard/pillar-large.obj', 'name': 'Pillar Large'},
      {'path': 'assets/graveyard/pillar-obelisk.obj', 'name': 'Pillar Obelisk'},
      {'path': 'assets/graveyard/pillar-small.obj', 'name': 'Pillar Small'},
      {'path': 'assets/graveyard/pillar-square.obj', 'name': 'Pillar Square'},
      {'path': 'assets/graveyard/pine-crooked.obj', 'name': 'Pine Crooked'},
      {
        'path': 'assets/graveyard/pine-fall-crooked.obj',
        'name': 'Pine Fall Crooked',
      },
      {'path': 'assets/graveyard/pine-fall.obj', 'name': 'Pine Fall'},
      {'path': 'assets/graveyard/pine.obj', 'name': 'Pine'},
      {'path': 'assets/graveyard/pumpkin-carved.obj', 'name': 'Pumpkin Carved'},
      {
        'path': 'assets/graveyard/pumpkin-tall-carved.obj',
        'name': 'Pumpkin Tall Carved',
      },
      {'path': 'assets/graveyard/pumpkin-tall.obj', 'name': 'Pumpkin Tall'},
      {'path': 'assets/graveyard/pumpkin.obj', 'name': 'Pumpkin'},
      {'path': 'assets/graveyard/road.obj', 'name': 'Road'},
      {'path': 'assets/graveyard/rocks-tall.obj', 'name': 'Rocks Tall'},
      {'path': 'assets/graveyard/rocks.obj', 'name': 'Rocks'},
      {'path': 'assets/graveyard/shovel-dirt.obj', 'name': 'Shovel Dirt'},
      {'path': 'assets/graveyard/shovel.obj', 'name': 'Shovel'},
      {
        'path': 'assets/graveyard/stone-wall-column.obj',
        'name': 'Stone Wall Column',
      },
      {
        'path': 'assets/graveyard/stone-wall-curve.obj',
        'name': 'Stone Wall Curve',
      },
      {
        'path': 'assets/graveyard/stone-wall-damaged.obj',
        'name': 'Stone Wall Damaged',
      },
      {'path': 'assets/graveyard/stone-wall.obj', 'name': 'Stone Wall'},
      {'path': 'assets/graveyard/trunk-long.obj', 'name': 'Trunk Long'},
      {'path': 'assets/graveyard/trunk.obj', 'name': 'Trunk'},
      {'path': 'assets/graveyard/urn.obj', 'name': 'Urn'},
    ];
  }

  static List<Map<String, String>> getAvailableFoodModels() {
    return [
      {'path': 'assets/foods/advocado-half.obj', 'name': 'Avocado Half'},
      {'path': 'assets/foods/apple-half.obj', 'name': 'Apple Half'},
      {'path': 'assets/foods/apple.obj', 'name': 'Apple'},
      {'path': 'assets/foods/avocado.obj', 'name': 'Avocado'},
      {'path': 'assets/foods/bacon-raw.obj', 'name': 'Bacon Raw'},
      {'path': 'assets/foods/bacon.obj', 'name': 'Bacon'},
      {'path': 'assets/foods/bag-flat.obj', 'name': 'Bag Flat'},
      {'path': 'assets/foods/bag.obj', 'name': 'Bag'},
      {'path': 'assets/foods/banana.obj', 'name': 'Banana'},
      {'path': 'assets/foods/barrel.obj', 'name': 'Barrel'},
      {'path': 'assets/foods/beet.obj', 'name': 'Beet'},
      {'path': 'assets/foods/bottle-ketchup.obj', 'name': 'Bottle Ketchup'},
      {'path': 'assets/foods/bottle-musterd.obj', 'name': 'Bottle Mustard'},
      {'path': 'assets/foods/bottle-oil.obj', 'name': 'Bottle Oil'},
      {'path': 'assets/foods/bowl-broth.obj', 'name': 'Bowl Broth'},
      {'path': 'assets/foods/bowl-cereal.obj', 'name': 'Bowl Cereal'},
      {'path': 'assets/foods/bowl-soup.obj', 'name': 'Bowl Soup'},
      {'path': 'assets/foods/bowl.obj', 'name': 'Bowl'},
      {'path': 'assets/foods/bread.obj', 'name': 'Bread'},
      {'path': 'assets/foods/broccoli.obj', 'name': 'Broccoli'},
      {
        'path': 'assets/foods/burger-cheese-double.obj',
        'name': 'Burger Cheese Double',
      },
      {'path': 'assets/foods/burger-cheese.obj', 'name': 'Burger Cheese'},
      {'path': 'assets/foods/burger-double.obj', 'name': 'Burger Double'},
      {'path': 'assets/foods/burger.obj', 'name': 'Burger'},
      {'path': 'assets/foods/cabbage.obj', 'name': 'Cabbage'},
      {'path': 'assets/foods/cake-birthday.obj', 'name': 'Cake Birthday'},
      {'path': 'assets/foods/cake-slicer.obj', 'name': 'Cake Slicer'},
      {'path': 'assets/foods/cake.obj', 'name': 'Cake'},
      {'path': 'assets/foods/can-open.obj', 'name': 'Can Open'},
      {'path': 'assets/foods/can-small.obj', 'name': 'Can Small'},
      {'path': 'assets/foods/can.obj', 'name': 'Can'},
      {
        'path': 'assets/foods/candy-bar-wrapper.obj',
        'name': 'Candy Bar Wrapper',
      },
      {'path': 'assets/foods/candy-bar.obj', 'name': 'Candy Bar'},
      {'path': 'assets/foods/carrot.obj', 'name': 'Carrot'},
      {'path': 'assets/foods/carton-small.obj', 'name': 'Carton Small'},
      {'path': 'assets/foods/carton.obj', 'name': 'Carton'},
      {'path': 'assets/foods/cauliflower.obj', 'name': 'Cauliflower'},
      {'path': 'assets/foods/celery-stick.obj', 'name': 'Celery Stick'},
      {'path': 'assets/foods/cheese-cut.obj', 'name': 'Cheese Cut'},
      {'path': 'assets/foods/cheese-slicer.obj', 'name': 'Cheese Slicer'},
      {'path': 'assets/foods/cheese.obj', 'name': 'Cheese'},
      {'path': 'assets/foods/cherries.obj', 'name': 'Cherries'},
      {'path': 'assets/foods/chinese.obj', 'name': 'Chinese Food'},
      {
        'path': 'assets/foods/chocolate-wrapper.obj',
        'name': 'Chocolate Wrapper',
      },
      {'path': 'assets/foods/chocolate.obj', 'name': 'Chocolate'},
      {
        'path': 'assets/foods/chopstic-decorative.obj',
        'name': 'Chopstick Decorative',
      },
      {'path': 'assets/foods/chopstick.obj', 'name': 'Chopstick'},
      {'path': 'assets/foods/cocktail.obj', 'name': 'Cocktail'},
      {'path': 'assets/foods/coconut-half.obj', 'name': 'Coconut Half'},
      {'path': 'assets/foods/coconut.obj', 'name': 'Coconut'},
      {'path': 'assets/foods/cookie-chocolate.obj', 'name': 'Cookie Chocolate'},
      {'path': 'assets/foods/cookie.obj', 'name': 'Cookie'},
      {'path': 'assets/foods/cooking-fork.obj', 'name': 'Cooking Fork'},
      {
        'path': 'assets/foods/cooking-knife-chopping.obj',
        'name': 'Cooking Knife Chopping',
      },
      {'path': 'assets/foods/cooking-knife.obj', 'name': 'Cooking Knife'},
      {'path': 'assets/foods/cooking-spatula.obj', 'name': 'Cooking Spatula'},
      {'path': 'assets/foods/cooking-spoon.obj', 'name': 'Cooking Spoon'},
      {'path': 'assets/foods/corn-dog.obj', 'name': 'Corn Dog'},
      {'path': 'assets/foods/corn.obj', 'name': 'Corn'},
      {'path': 'assets/foods/croissant.obj', 'name': 'Croissant'},
      {'path': 'assets/foods/cup-coffee.obj', 'name': 'Cup Coffee'},
      {'path': 'assets/foods/cup-saucer.obj', 'name': 'Cup Saucer'},
      {'path': 'assets/foods/cup-tea.obj', 'name': 'Cup Tea'},
      {'path': 'assets/foods/cup.obj', 'name': 'Cup'},
      {'path': 'assets/foods/cupcake.obj', 'name': 'Cupcake'},
      {
        'path': 'assets/foods/cutting-board-japanese.obj',
        'name': 'Cutting Board Japanese',
      },
      {
        'path': 'assets/foods/cutting-board-round.obj',
        'name': 'Cutting Board Round',
      },
      {'path': 'assets/foods/cutting-board.obj', 'name': 'Cutting Board'},
      {'path': 'assets/foods/dim-sum.obj', 'name': 'Dim Sum'},
      {'path': 'assets/foods/donut-chocolate.obj', 'name': 'Donut Chocolate'},
      {'path': 'assets/foods/donut-sprinkles.obj', 'name': 'Donut Sprinkles'},
      {'path': 'assets/foods/donut.obj', 'name': 'Donut'},
      {'path': 'assets/foods/egg-cooked.obj', 'name': 'Egg Cooked'},
      {'path': 'assets/foods/egg-cup.obj', 'name': 'Egg Cup'},
      {'path': 'assets/foods/egg-half.obj', 'name': 'Egg Half'},
      {'path': 'assets/foods/egg.obj', 'name': 'Egg'},
      {'path': 'assets/foods/eggplant.obj', 'name': 'Eggplant'},
      {'path': 'assets/foods/fish-bones.obj', 'name': 'Fish Bones'},
      {'path': 'assets/foods/fish.obj', 'name': 'Fish'},
      {'path': 'assets/foods/frappe.obj', 'name': 'Frappe'},
      {'path': 'assets/foods/fries-empty.obj', 'name': 'Fries Empty'},
      {'path': 'assets/foods/fries.obj', 'name': 'Fries'},
      {
        'path': 'assets/foods/frikandel-speciaal.obj',
        'name': 'Frikandel Speciaal',
      },
      {'path': 'assets/foods/frying-pan-lid.obj', 'name': 'Frying Pan Lid'},
      {'path': 'assets/foods/frying-pan.obj', 'name': 'Frying Pan'},
      {
        'path': 'assets/foods/ginger-bread-cutter.obj',
        'name': 'Ginger Bread Cutter',
      },
      {'path': 'assets/foods/ginger-bread.obj', 'name': 'Ginger Bread'},
      {'path': 'assets/foods/glass-wine.obj', 'name': 'Glass Wine'},
      {'path': 'assets/foods/glass.obj', 'name': 'Glass'},
      {'path': 'assets/foods/grapes.obj', 'name': 'Grapes'},
      {'path': 'assets/foods/honey.obj', 'name': 'Honey'},
      {'path': 'assets/foods/hot-dog-raw.obj', 'name': 'Hot Dog Raw'},
      {'path': 'assets/foods/hot-dog.obj', 'name': 'Hot Dog'},
      {'path': 'assets/foods/ice-cream-cne.obj', 'name': 'Ice Cream Cone'},
      {'path': 'assets/foods/ice-cream-cup.obj', 'name': 'Ice Cream Cup'},
      {
        'path': 'assets/foods/ice-cream-scoop-chocolate.obj',
        'name': 'Ice Cream Scoop Chocolate',
      },
      {
        'path': 'assets/foods/ice-cream-scoop-mint.obj',
        'name': 'Ice Cream Scoop Mint',
      },
      {'path': 'assets/foods/ice-cream.obj', 'name': 'Ice Cream'},
      {'path': 'assets/foods/knife-block.obj', 'name': 'Knife Block'},
      {'path': 'assets/foods/leek.obj', 'name': 'Leek'},
      {'path': 'assets/foods/lemon-half.obj', 'name': 'Lemon Half'},
      {'path': 'assets/foods/lemon.obj', 'name': 'Lemon'},
      {'path': 'assets/foods/loaf-baguette.obj', 'name': 'Loaf Baguette'},
      {'path': 'assets/foods/loaf-round.obj', 'name': 'Loaf Round'},
      {'path': 'assets/foods/loaf.obj', 'name': 'Loaf'},
      {'path': 'assets/foods/lollypop.obj', 'name': 'Lollypop'},
      {'path': 'assets/foods/maki-roe.obj', 'name': 'Maki Roe'},
      {'path': 'assets/foods/maki-salmon.obj', 'name': 'Maki Salmon'},
      {'path': 'assets/foods/maki-vegetable.obj', 'name': 'Maki Vegetable'},
      {'path': 'assets/foods/meat-cooked.obj', 'name': 'Meat Cooked'},
      {'path': 'assets/foods/meat-patty.obj', 'name': 'Meat Patty'},
      {'path': 'assets/foods/meat-raw.obj', 'name': 'Meat Raw'},
      {'path': 'assets/foods/meat-ribs.obj', 'name': 'Meat Ribs'},
      {'path': 'assets/foods/meat-sausage.obj', 'name': 'Meat Sausage'},
      {'path': 'assets/foods/meat-tenderizer.obj', 'name': 'Meat Tenderizer'},
      {'path': 'assets/foods/mincemeat-pie.obj', 'name': 'Mincemeat Pie'},
      {'path': 'assets/foods/mortar-pestle.obj', 'name': 'Mortar Pestle'},
      {'path': 'assets/foods/mortar.obj', 'name': 'Mortar'},
      {'path': 'assets/foods/muffin.obj', 'name': 'Muffin'},
      {'path': 'assets/foods/mug.obj', 'name': 'Mug'},
      {'path': 'assets/foods/mushroom-half.obj', 'name': 'Mushroom Half'},
      {'path': 'assets/foods/mushroom.obj', 'name': 'Mushroom'},
      {'path': 'assets/foods/mussel-open.obj', 'name': 'Mussel Open'},
      {'path': 'assets/foods/mussel.obj', 'name': 'Mussel'},
      {'path': 'assets/foods/onion-half.obj', 'name': 'Onion Half'},
      {'path': 'assets/foods/onion.obj', 'name': 'Onion'},
      {'path': 'assets/foods/orange.obj', 'name': 'Orange'},
      {'path': 'assets/foods/pan-stew.obj', 'name': 'Pan Stew'},
      {'path': 'assets/foods/pan.obj', 'name': 'Pan'},
      {'path': 'assets/foods/pancakes.obj', 'name': 'Pancakes'},
      {'path': 'assets/foods/paprika-slice.obj', 'name': 'Paprika Slice'},
      {'path': 'assets/foods/paprika.obj', 'name': 'Paprika'},
      {'path': 'assets/foods/peanut-butter.obj', 'name': 'Peanut Butter'},
      {'path': 'assets/foods/pear-half.obj', 'name': 'Pear Half'},
      {'path': 'assets/foods/pear.obj', 'name': 'Pear'},
      {'path': 'assets/foods/pepper-mill.obj', 'name': 'Pepper Mill'},
      {'path': 'assets/foods/pepper.obj', 'name': 'Pepper'},
      {'path': 'assets/foods/pie.obj', 'name': 'Pie'},
      {'path': 'assets/foods/pineapple.obj', 'name': 'Pineapple'},
      {'path': 'assets/foods/pizza-box.obj', 'name': 'Pizza Box'},
      {'path': 'assets/foods/pizza-cutter.obj', 'name': 'Pizza Cutter'},
      {'path': 'assets/foods/pizza.obj', 'name': 'Pizza'},
      {'path': 'assets/foods/plate-broken.obj', 'name': 'Plate Broken'},
      {'path': 'assets/foods/plate-deep.obj', 'name': 'Plate Deep'},
      {'path': 'assets/foods/plate-dinner.obj', 'name': 'Plate Dinner'},
      {'path': 'assets/foods/plate-rectangle.obj', 'name': 'Plate Rectangle'},
      {'path': 'assets/foods/plate-sauerkraut.obj', 'name': 'Plate Sauerkraut'},
      {'path': 'assets/foods/plate.obj', 'name': 'Plate'},
      {
        'path': 'assets/foods/popsicle-chocolate.obj',
        'name': 'Popsicle Chocolate',
      },
      {'path': 'assets/foods/popsicle-stick.obj', 'name': 'Popsicle Stick'},
      {'path': 'assets/foods/popsicle.obj', 'name': 'Popsicle'},
      {'path': 'assets/foods/pot-lid.obj', 'name': 'Pot Lid'},
      {'path': 'assets/foods/pot-stew-lid.obj', 'name': 'Pot Stew Lid'},
      {'path': 'assets/foods/pot-stew.obj', 'name': 'Pot Stew'},
      {'path': 'assets/foods/pot.obj', 'name': 'Pot'},
      {'path': 'assets/foods/pudding.obj', 'name': 'Pudding'},
      {'path': 'assets/foods/pumpkin-basic.obj', 'name': 'Pumpkin Basic'},
      {'path': 'assets/foods/pumpkin.obj', 'name': 'Pumpkin'},
      {'path': 'assets/foods/radish.obj', 'name': 'Radish'},
      {'path': 'assets/foods/rice-ball.obj', 'name': 'Rice Ball'},
      {'path': 'assets/foods/rollingPin.obj', 'name': 'Rolling Pin'},
      {'path': 'assets/foods/salad.obj', 'name': 'Salad'},
      {'path': 'assets/foods/sandwich.obj', 'name': 'Sandwich'},
      {'path': 'assets/foods/sausage-half.obj', 'name': 'Sausage Half'},
      {'path': 'assets/foods/sausage.obj', 'name': 'Sausage'},
      {'path': 'assets/foods/shaker-pepper.obj', 'name': 'Shaker Pepper'},
      {'path': 'assets/foods/shaker-salt.obj', 'name': 'Shaker Salt'},
      {
        'path': 'assets/foods/skewer-vegetables.obj',
        'name': 'Skewer Vegetables',
      },
      {'path': 'assets/foods/skewer.obj', 'name': 'Skewer'},
      {'path': 'assets/foods/soda-bottle.obj', 'name': 'Soda Bottle'},
      {'path': 'assets/foods/soda-can-crushed.obj', 'name': 'Soda Can Crushed'},
      {'path': 'assets/foods/soda-can.obj', 'name': 'Soda Can'},
      {'path': 'assets/foods/soda-glass.obj', 'name': 'Soda Glass'},
      {'path': 'assets/foods/soda.obj', 'name': 'Soda'},
      {'path': 'assets/foods/soy.obj', 'name': 'Soy'},
      {'path': 'assets/foods/steamer.obj', 'name': 'Steamer'},
      {'path': 'assets/foods/strawberry.obj', 'name': 'Strawberry'},
      {'path': 'assets/foods/styrofoam-dinner.obj', 'name': 'Styrofoam Dinner'},
      {'path': 'assets/foods/styrofoam.obj', 'name': 'Styrofoam'},
      {'path': 'assets/foods/sub.obj', 'name': 'Sub'},
      {'path': 'assets/foods/sundae.obj', 'name': 'Sundae'},
      {'path': 'assets/foods/sushi-egg.obj', 'name': 'Sushi Egg'},
      {'path': 'assets/foods/sushi-salmon.obj', 'name': 'Sushi Salmon'},
      {'path': 'assets/foods/taco.obj', 'name': 'Taco'},
      {'path': 'assets/foods/tajine-lid.obj', 'name': 'Tajine Lid'},
      {'path': 'assets/foods/tajine.obj', 'name': 'Tajine'},
      {'path': 'assets/foods/tomato-slice.obj', 'name': 'Tomato Slice'},
      {'path': 'assets/foods/tomato.obj', 'name': 'Tomato'},
      {'path': 'assets/foods/turkey.obj', 'name': 'Turkey'},
      {'path': 'assets/foods/utensil-fork.obj', 'name': 'Utensil Fork'},
      {'path': 'assets/foods/utensil-knife.obj', 'name': 'Utensil Knife'},
      {'path': 'assets/foods/utensil-spoon.obj', 'name': 'Utensil Spoon'},
      {'path': 'assets/foods/waffle.obj', 'name': 'Waffle'},
      {'path': 'assets/foods/watermelon.obj', 'name': 'Watermelon'},
      {'path': 'assets/foods/whipped-cream.obj', 'name': 'Whipped Cream'},
      {'path': 'assets/foods/whisk.obj', 'name': 'Whisk'},
      {'path': 'assets/foods/whole-ham.obj', 'name': 'Whole Ham'},
      {'path': 'assets/foods/wholer-ham.obj', 'name': 'Wholer Ham'},
      {'path': 'assets/foods/wine-red.obj', 'name': 'Wine Red'},
      {'path': 'assets/foods/wine-white.obj', 'name': 'Wine White'},
    ];
  }

  static List<Map<String, String>> getAvailableCharacterModels() {
    return [
      {'path': 'assets/characters/aid_hearing.obj', 'name': 'Aid Hearing'},
      {
        'path': 'assets/characters/aid-cane-blind.obj',
        'name': 'Aid Cane Blind',
      },
      {
        'path': 'assets/characters/aid-cane-low-vision.obj',
        'name': 'Aid Cane Low Vision',
      },
      {'path': 'assets/characters/aid-cane.obj', 'name': 'Aid Cane'},
      {'path': 'assets/characters/aid-crutch.obj', 'name': 'Aid Crutch'},
      {
        'path': 'assets/characters/aid-defibrillator-green.obj',
        'name': 'Aid Defibrillator Green',
      },
      {
        'path': 'assets/characters/aid-defibrillator-red.obj',
        'name': 'Aid Defibrillator Red',
      },
      {'path': 'assets/characters/aid-glasses.obj', 'name': 'Aid Glasses'},
      {'path': 'assets/characters/aid-mask.obj', 'name': 'Aid Mask'},
      {
        'path': 'assets/characters/aid-sunglasses.obj',
        'name': 'Aid Sunglasses',
      },
      {
        'path': 'assets/characters/character-female-a.obj',
        'name': 'Character Female A',
      },
      {
        'path': 'assets/characters/character-female-b.obj',
        'name': 'Character Female B',
      },
      {
        'path': 'assets/characters/character-female-c.obj',
        'name': 'Character Female C',
      },
      {
        'path': 'assets/characters/character-female-d.obj',
        'name': 'Character Female D',
      },
      {
        'path': 'assets/characters/character-female-e.obj',
        'name': 'Character Female E',
      },
      {
        'path': 'assets/characters/character-female-f.obj',
        'name': 'Character Female F',
      },
      {
        'path': 'assets/characters/character-male-a.obj',
        'name': 'Character Male A',
      },
      {
        'path': 'assets/characters/character-male-b.obj',
        'name': 'Character Male B',
      },
      {
        'path': 'assets/characters/character-male-c.obj',
        'name': 'Character Male C',
      },
      {
        'path': 'assets/characters/character-male-d.obj',
        'name': 'Character Male D',
      },
      {
        'path': 'assets/characters/character-male-e.obj',
        'name': 'Character Male E',
      },
      {
        'path': 'assets/characters/character-male-f.obj',
        'name': 'Character Male F',
      },
      {
        'path': 'assets/characters/wheelchair-deluxe.obj',
        'name': 'Wheelchair Deluxe',
      },
      {
        'path': 'assets/characters/wheelchair-power-deluxe.obj',
        'name': 'Wheelchair Power Deluxe',
      },
      {
        'path': 'assets/characters/wheelchair-power.obj',
        'name': 'Wheelchair Power',
      },
      {'path': 'assets/characters/wheelchair.obj', 'name': 'Wheelchair'},
    ];
  }

  static List<Map<String, String>> getAllAvailableModels() {
    return [
      ...getAvailableModels(),
      ...getAvailableFoodModels(),
      ...getAvailableCharacterModels(),
    ];
  }
}
