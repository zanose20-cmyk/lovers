class NotificationModel {
  String? notifId;
  String? userId;
  String? type;
  String? title;
  String? body;
  Map<String, dynamic>? data;
  String? imageUrl;
  bool? isRead;
  DateTime? readAt;
  DateTime? createdAt;

  NotificationModel({
    this.notifId,
    this.userId,
    this.type,
    this.title,
    this.body,
    this.data,
    this.imageUrl,
    this.isRead,
    this.readAt,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map json) => NotificationModel(
        notifId: json['notifId'],
        userId: json['userId'],
        type: json['type'],
        title: json['title'],
        body: json['body'],
        data: json['data'],
        imageUrl: json['imageUrl'],
        isRead: json['isRead'],
        readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );

  Map toJson() => {
        'notifId': notifId,
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'imageUrl': imageUrl,
        'isRead': isRead,
        'readAt': readAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };
}
