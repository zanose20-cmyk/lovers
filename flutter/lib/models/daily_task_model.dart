class TaskReward {
  int? coins;
  int? diamonds;
  int? xp;

  TaskReward({this.coins, this.diamonds, this.xp});

  factory TaskReward.fromJson(Map json) => TaskReward(
        coins: json['coins'],
        diamonds: json['diamonds'],
        xp: json['xp'],
      );

  Map toJson() => {'coins': coins, 'diamonds': diamonds, 'xp': xp};
}

class TaskRequirement {
  int? target;
  String? unit;

  TaskRequirement({this.target, this.unit});

  factory TaskRequirement.fromJson(Map json) => TaskRequirement(
        target: json['target'],
        unit: json['unit'],
      );

  Map toJson() => {'target': target, 'unit': unit};
}

class DailyTaskModel {
  String? taskId;
  String? title;
  String? description;
  String? type;
  TaskReward? reward;
  TaskRequirement? requirement;
  String? icon;
  bool? isActive;
  DateTime? createdAt;
  int? progress;
  int? target;
  bool? completed;
  bool? claimed;

  DailyTaskModel({
    this.taskId,
    this.title,
    this.description,
    this.type,
    this.reward,
    this.requirement,
    this.icon,
    this.isActive,
    this.createdAt,
    this.progress,
    this.target,
    this.completed,
    this.claimed,
  });

  factory DailyTaskModel.fromJson(Map json) => DailyTaskModel(
        taskId: json['taskId'],
        title: json['title'],
        description: json['description'],
        type: json['type'],
        reward: json['reward'] != null ? TaskReward.fromJson(json['reward']) : null,
        requirement: json['requirement'] != null ? TaskRequirement.fromJson(json['requirement']) : null,
        icon: json['icon'],
        isActive: json['isActive'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
        progress: json['progress'],
        target: json['target'],
        completed: json['completed'],
        claimed: json['claimed'],
      );

  Map toJson() => {
        'taskId': taskId,
        'title': title,
        'description': description,
        'type': type,
        'reward': reward?.toJson(),
        'requirement': requirement?.toJson(),
        'icon': icon,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'progress': progress,
        'target': target,
        'completed': completed,
        'claimed': claimed,
      };
}
