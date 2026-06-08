class Seat {
  int? index;
  String? userId;
  String? displayName;
  String? avatarUrl;
  bool? isMuted;
  bool? isLocked;
  DateTime? joinedAt;

  Seat({
    this.index,
    this.userId,
    this.displayName,
    this.avatarUrl,
    this.isMuted,
    this.isLocked,
    this.joinedAt,
  });

  factory Seat.fromJson(Map json) => Seat(
        index: json['index'],
        userId: json['userId'],
        displayName: json['displayName'],
        avatarUrl: json['avatarUrl'],
        isMuted: json['isMuted'],
        isLocked: json['isLocked'],
        joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt']) : null,
      );

  Map toJson() => {
        'index': index,
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'isMuted': isMuted,
        'isLocked': isLocked,
        'joinedAt': joinedAt?.toIso8601String(),
      };
}

class RoomModel {
  String? roomId;
  String? title;
  String? ownerId;
  String? ownerName;
  String? type;
  String? password;
  int? capacity;
  int? maxCapacity;
  bool? isLocked;
  List<Seat>? seats;
  List<String>? moderators;
  List<String>? coOwners;
  Map<String, dynamic>? metadata;
  String? background;
  String? entranceEffects;
  DateTime? createdAt;
  DateTime? updatedAt;

  RoomModel({
    this.roomId,
    this.title,
    this.ownerId,
    this.ownerName,
    this.type,
    this.password,
    this.capacity,
    this.maxCapacity,
    this.isLocked,
    this.seats,
    this.moderators,
    this.coOwners,
    this.metadata,
    this.background,
    this.entranceEffects,
    this.createdAt,
    this.updatedAt,
  });

  factory RoomModel.fromJson(Map json) => RoomModel(
        roomId: json['roomId'],
        title: json['title'],
        ownerId: json['ownerId'],
        ownerName: json['ownerName'],
        type: json['type'],
        password: json['password'],
        capacity: json['capacity'],
        maxCapacity: json['maxCapacity'],
        isLocked: json['isLocked'],
        seats: json['seats'] != null ? (json['seats'] as List).map((e) => Seat.fromJson(e)).toList() : null,
        moderators: json['moderators'] != null ? List<String>.from(json['moderators']) : null,
        coOwners: json['coOwners'] != null ? List<String>.from(json['coOwners']) : null,
        metadata: json['metadata'],
        background: json['background'],
        entranceEffects: json['entranceEffects'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      );

  Map toJson() => {
        'roomId': roomId,
        'title': title,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'type': type,
        'password': password,
        'capacity': capacity,
        'maxCapacity': maxCapacity,
        'isLocked': isLocked,
        'seats': seats?.map((e) => e.toJson()).toList(),
        'moderators': moderators,
        'coOwners': coOwners,
        'metadata': metadata,
        'background': background,
        'entranceEffects': entranceEffects,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  int get occupiedSeats => seats?.where((s) => s.userId != null).length ?? 0;
}
