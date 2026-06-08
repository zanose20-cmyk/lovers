class MessageModel {
  String? messageId;
  String? fromUserId;
  String? toUserId;
  String? roomId;
  String? type;
  String? content;
  List<Map<String, dynamic>>? attachments;
  String? translatedText;
  bool? isRead;
  DateTime? createdAt;

  MessageModel({
    this.messageId,
    this.fromUserId,
    this.toUserId,
    this.roomId,
    this.type,
    this.content,
    this.attachments,
    this.translatedText,
    this.isRead,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map json) => MessageModel(
        messageId: json['messageId'],
        fromUserId: json['fromUserId'],
        toUserId: json['toUserId'],
        roomId: json['roomId'],
        type: json['type'],
        content: json['content'],
        attachments: json['attachments'] != null ? List<Map<String, dynamic>>.from(json['attachments']) : null,
        translatedText: json['translatedText'],
        isRead: json['isRead'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );

  Map toJson() => {
        'messageId': messageId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'roomId': roomId,
        'type': type,
        'content': content,
        'attachments': attachments,
        'translatedText': translatedText,
        'isRead': isRead,
        'createdAt': createdAt?.toIso8601String(),
      };
}

class ConversationModel {
  Map<String, dynamic>? user;
  MessageModel? lastMessage;
  int? unread;

  ConversationModel({this.user, this.lastMessage, this.unread});

  factory ConversationModel.fromJson(Map json) => ConversationModel(
        user: json['user'],
        lastMessage: json['lastMessage'] != null ? MessageModel.fromJson(json['lastMessage']) : null,
        unread: json['unread'],
      );

  Map toJson() => {
        'user': user,
        'lastMessage': lastMessage?.toJson(),
        'unread': unread,
      };
}
