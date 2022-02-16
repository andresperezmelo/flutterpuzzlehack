import 'package:uuid/uuid.dart';

class UserApp {
  late String uid;
  late String name;
  late int level;
  late int points;
  late DateTime createdAt;

  UserApp({
    required this.uid,
    required this.name,
    required this.level,
    required this.points,
    required this.createdAt,
  });

  factory UserApp.fromJson(Map<String, dynamic> json) => UserApp(
        uid: json["uid"],
        name: json["name"],
        level: json["level"],
        points: json["points"],
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "name": name,
        "level": level,
        "points": points,
        "createdAt": createdAt.toIso8601String(),
      };

  factory UserApp.voidValues() => UserApp(
        uid: "",
        name: "",
        level: 0,
        points: 0,
        createdAt: DateTime.now(),
      );

//generate uid
  static String generateUid() {
    return Uuid().v4().replaceAll("-", "");
  }
}
