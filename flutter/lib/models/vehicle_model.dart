class VehicleModel {
  String? sku;
  String? name;
  String? description;
  String? type;
  String? rarity;
  int? priceCoins;
  int? priceDiamonds;
  int? durationDays;
  String? imageUrl;
  String? animationUrl;
  String? model3dUrl;
  String? entryEffect;
  String? entryAnimationUrl;
  List<String>? colors;
  Map<String, dynamic>? effects;
  Map<String, dynamic>? meta;
  bool? isActive;
  DateTime? createdAt;

  VehicleModel({
    this.sku,
    this.name,
    this.description,
    this.type,
    this.rarity,
    this.priceCoins,
    this.priceDiamonds,
    this.durationDays,
    this.imageUrl,
    this.animationUrl,
    this.model3dUrl,
    this.entryEffect,
    this.entryAnimationUrl,
    this.colors,
    this.effects,
    this.meta,
    this.isActive,
    this.createdAt,
  });

  factory VehicleModel.fromJson(Map json) => VehicleModel(
        sku: json['sku'],
        name: json['name'],
        description: json['description'],
        type: json['type'],
        rarity: json['rarity'],
        priceCoins: json['priceCoins'],
        priceDiamonds: json['priceDiamonds'],
        durationDays: json['durationDays'],
        imageUrl: json['imageUrl'],
        animationUrl: json['animationUrl'],
        model3dUrl: json['model3dUrl'],
        entryEffect: json['entryEffect'],
        entryAnimationUrl: json['entryAnimationUrl'],
        colors: json['colors'] != null ? List<String>.from(json['colors']) : null,
        effects: json['effects'],
        meta: json['meta'],
        isActive: json['isActive'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );

  Map toJson() => {
        'sku': sku,
        'name': name,
        'description': description,
        'type': type,
        'rarity': rarity,
        'priceCoins': priceCoins,
        'priceDiamonds': priceDiamonds,
        'durationDays': durationDays,
        'imageUrl': imageUrl,
        'animationUrl': animationUrl,
        'model3dUrl': model3dUrl,
        'entryEffect': entryEffect,
        'entryAnimationUrl': entryAnimationUrl,
        'colors': colors,
        'effects': effects,
        'meta': meta,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };
}
