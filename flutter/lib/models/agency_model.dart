class AgencyMember {
  String? userId;
  String? role;
  DateTime? joinedAt;
  int? salary;

  AgencyMember({this.userId, this.role, this.joinedAt, this.salary});

  factory AgencyMember.fromJson(Map json) => AgencyMember(
        userId: json['userId'],
        role: json['role'],
        joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt']) : null,
        salary: json['salary'],
      );

  Map toJson() => {
        'userId': userId,
        'role': role,
        'joinedAt': joinedAt?.toIso8601String(),
        'salary': salary,
      };
}

class AgencyStats {
  int? totalMembers;
  int? totalGiftsReceived;
  int? totalEarnings;
  int? rank;

  AgencyStats({this.totalMembers, this.totalGiftsReceived, this.totalEarnings, this.rank});

  factory AgencyStats.fromJson(Map json) => AgencyStats(
        totalMembers: json['totalMembers'],
        totalGiftsReceived: json['totalGiftsReceived'],
        totalEarnings: json['totalEarnings'],
        rank: json['rank'],
      );

  Map toJson() => {
        'totalMembers': totalMembers,
        'totalGiftsReceived': totalGiftsReceived,
        'totalEarnings': totalEarnings,
        'rank': rank,
      };
}

class AgencyModel {
  String? agencyId;
  String? name;
  String? description;
  String? logo;
  String? coverImage;
  String? ownerId;
  List<String>? managers;
  List<AgencyMember>? members;
  AgencyStats? stats;
  bool? isActive;
  DateTime? createdAt;
  DateTime? updatedAt;

  AgencyModel({
    this.agencyId,
    this.name,
    this.description,
    this.logo,
    this.coverImage,
    this.ownerId,
    this.managers,
    this.members,
    this.stats,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory AgencyModel.fromJson(Map json) => AgencyModel(
        agencyId: json['agencyId'],
        name: json['name'],
        description: json['description'],
        logo: json['logo'],
        coverImage: json['coverImage'],
        ownerId: json['ownerId'],
        managers: json['managers'] != null ? List<String>.from(json['managers']) : null,
        members: json['members'] != null ? (json['members'] as List).map((e) => AgencyMember.fromJson(e)).toList() : null,
        stats: json['stats'] != null ? AgencyStats.fromJson(json['stats']) : null,
        isActive: json['isActive'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      );

  Map toJson() => {
        'agencyId': agencyId,
        'name': name,
        'description': description,
        'logo': logo,
        'coverImage': coverImage,
        'ownerId': ownerId,
        'managers': managers,
        'members': members?.map((e) => e.toJson()).toList(),
        'stats': stats?.toJson(),
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
