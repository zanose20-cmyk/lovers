class TransactionModel {
  String? txId;
  String? userId;
  String? type;
  int? amountCoins;
  int? amountDiamonds;
  String? relatedUserId;
  String? giftSku;
  String? roomId;
  String? status;
  DateTime? createdAt;

  TransactionModel({
    this.txId,
    this.userId,
    this.type,
    this.amountCoins,
    this.amountDiamonds,
    this.relatedUserId,
    this.giftSku,
    this.roomId,
    this.status,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map json) => TransactionModel(
        txId: json['txId'],
        userId: json['userId'],
        type: json['type'],
        amountCoins: json['amountCoins'],
        amountDiamonds: json['amountDiamonds'],
        relatedUserId: json['relatedUserId'],
        giftSku: json['giftSku'],
        roomId: json['roomId'],
        status: json['status'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );

  Map toJson() => {
        'txId': txId,
        'userId': userId,
        'type': type,
        'amountCoins': amountCoins,
        'amountDiamonds': amountDiamonds,
        'relatedUserId': relatedUserId,
        'giftSku': giftSku,
        'roomId': roomId,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
      };
}
