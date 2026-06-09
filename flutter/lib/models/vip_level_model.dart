class VIPLevelModel {
  int? level;
  String? name;
  Map<String, dynamic>? badge;
  Map<String, dynamic>? frame;
  String? entryEffect;
  String? entryAnimationUrl;
  String? color;
  List<String>? benefits;
  Map<String, dynamic>? requirements;
  int? priceCoins;
  int? priceCoins3Months;
  int? priceCoins12Months;
  int? priceDiamonds;
  int? durationDays;
  bool? isActive;
  DateTime? createdAt;

  VIPLevelModel({
    this.level,
    this.name,
    this.badge,
    this.frame,
    this.entryEffect,
    this.entryAnimationUrl,
    this.color,
    this.benefits,
    this.requirements,
    this.priceCoins,
    this.priceCoins3Months,
    this.priceCoins12Months,
    this.priceDiamonds,
    this.durationDays,
    this.isActive,
    this.createdAt,
  });

  factory VIPLevelModel.fromJson(Map json) => VIPLevelModel(
        level: json['level'],
        name: json['name'],
        badge: json['badge'],
        frame: json['frame'],
        entryEffect: json['entryEffect'],
        entryAnimationUrl: json['entryAnimationUrl'],
        color: json['color'],
        benefits: json['benefits'] != null ? List<String>.from(json['benefits']) : null,
        requirements: json['requirements'],
        priceCoins: json['priceCoins'],
        priceCoins3Months: json['priceCoins3Months'],
        priceCoins12Months: json['priceCoins12Months'],
        priceDiamonds: json['priceDiamonds'],
        durationDays: json['durationDays'],
        isActive: json['isActive'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );

  Map toJson() => {
        'level': level,
        'name': name,
        'badge': badge,
        'frame': frame,
        'entryEffect': entryEffect,
        'entryAnimationUrl': entryAnimationUrl,
        'color': color,
        'benefits': benefits,
        'requirements': requirements,
        'priceCoins': priceCoins,
        'priceCoins3Months': priceCoins3Months,
        'priceCoins12Months': priceCoins12Months,
        'priceDiamonds': priceDiamonds,
        'durationDays': durationDays,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
      };
}
