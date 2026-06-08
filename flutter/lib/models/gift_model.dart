class GiftModel {
  String? sku;
  String? name;
  String? type;
  String? rarity;
  int? priceCoins;
  int? priceDiamonds;
  Map<String, dynamic>? prices;
  String? imageUrl;
  String? animationUrl;
  String? asset3dUrl;
  bool? fullscreenEffect;
  String? entryEffect;
  Map<String, dynamic>? effects;
  Map<String, dynamic>? meta;
  DateTime? createdAt;

  GiftModel({
    this.sku,
    this.name,
    this.type,
    this.rarity,
    this.priceCoins,
    this.priceDiamonds,
    this.prices,
    this.imageUrl,
    this.animationUrl,
    this.asset3dUrl,
    this.fullscreenEffect,
    this.entryEffect,
    this.effects,
    this.meta,
    this.createdAt,
  });

  factory GiftModel.fromJson(Map json) => GiftModel(
        sku: json['sku'],
        name: json['name'],
        type: json['type'],
        rarity: json['rarity'],
        priceCoins: json['priceCoins'],
        priceDiamonds: json['priceDiamonds'],
        prices: json['prices'],
        imageUrl: json['imageUrl'],
        animationUrl: json['animationUrl'],
        asset3dUrl: json['asset3dUrl'],
        fullscreenEffect: json['fullscreenEffect'],
        entryEffect: json['entryEffect'],
        effects: json['effects'],
        meta: json['meta'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );

  Map toJson() => {
        'sku': sku,
        'name': name,
        'type': type,
        'rarity': rarity,
        'priceCoins': priceCoins,
        'priceDiamonds': priceDiamonds,
        'prices': prices,
        'imageUrl': imageUrl,
        'animationUrl': animationUrl,
        'asset3dUrl': asset3dUrl,
        'fullscreenEffect': fullscreenEffect,
        'entryEffect': entryEffect,
        'effects': effects,
        'meta': meta,
        'createdAt': createdAt?.toIso8601String(),
      };
}
