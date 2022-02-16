import 'package:firebase_database/firebase_database.dart';
import 'package:puzzleapp/db/hive_dao_local.dart';
import 'package:puzzleapp/model/puzzle.dart';
import 'package:puzzleapp/model/user.dart';
import '../model/info.dart';
import '../static/val_statics.dart';

class RealtimeDB {
  static Future<Info> createUser({required Map<String, dynamic> data}) async {
    bool status = false;
    String message = "Iniciando";
    //UserApp userApp = RepositiryUser().userApp;
    final FirebaseDatabase database = FirebaseDatabase.instance;
    String path = 'users/${data['uid']}';
    final DatabaseReference databaseReference = database.ref().child(path);

    try {
      await databaseReference.set(data);
      status = true;
      message = "Sucess";
    } catch (e) {
      status = false;
      message = "Error to save: $e";
    }

    return Info(status: status, message: message);
  }

  static Future<List<UserApp>> getUsersOnline() async {
    final FirebaseDatabase database = FirebaseDatabase.instance;
    String path = 'online';
    final DatabaseReference databaseReference = database.ref().child(path);

    List<UserApp> users = [];
    try {
      await databaseReference.once().then((DatabaseEvent databaseEvent) {
        if (databaseEvent.snapshot.exists) {
          Map<Object?, Object?> values = databaseEvent.snapshot.value as Map<Object?, Object?>;
          values.forEach((key, value) async {
            Map use = value as Map;
            Map<String, dynamic> userMap = {
              'uid': key,
              'name': use['name'],
              'level': use['level'],
              'points': use['points'],
              'createdAt': use['createdAt'] != null ? use['createdAt'] : DateTime.now(),
            };
            int hours = 0;
            if (use['createdAt'] == null) {
              //delete user online
              await databaseReference.child(key.toString()).remove();
            } else {
              DateTime now = DateTime.now();
              DateTime createdAt = DateTime.parse(use['createdAt']);
              Duration duration = now.difference(createdAt);
              hours = duration.inHours;
              //print("hours: $hours");
              if (hours > 12) {
                //delete user online
                await databaseReference.child(key.toString()).remove();
              } else {
                UserApp user = UserApp.fromJson(userMap);
                users.add(user);
              }
            }
          });
        } else {
          print("No hay usuarios en linea");
        }
      });
    } catch (e) {
      print("Error to get users online: $e");
    }

    return users;
  }

  static Future<Info> sendChallenge({required UserApp userApp, required Puzzle puzzle}) async {
    bool status = false;
    String message = "Iniciando";
    final FirebaseDatabase database = FirebaseDatabase.instance;
    String path = 'challenges/${userApp.uid}/${ValStatics.getRamdomId}';
    final DatabaseReference databaseReference = database.ref().child(path);

    Map<String, dynamic> puzzl = puzzle.toJson();
    puzzl['image'] = puzzle.image.toString();

    Map<String, dynamic> user = await HiveDaoLocal.getData(id: "user");

    Map<String, dynamic> data = {
      'uid': user['uid'], //uid del retador
      'name': user['name'], //nombre del retador
      'level': userApp.level,
      'points': userApp.points,
      'puzzle': puzzl,
    };

    try {
      await databaseReference.update(data);
      status = true;
      message = "Sucess";
    } catch (e) {
      status = false;
      message = "Error to save: $e";
    }

    return Info(status: status, message: message);
  }

  //status online
  static Future<Info> setUserOnline({required UserApp userApp}) async {
    bool status = false;
    String message = "Iniciando";
    final FirebaseDatabase database = FirebaseDatabase.instance;
    final DatabaseReference databaseReference = database.ref().child('online/${userApp.uid}');
    final DatabaseReference databaseChallenge = database.ref().child('challenges/${userApp.uid}');

    try {
      await databaseReference.set(userApp.toJson());
      Map<String, dynamic> map = {
        "uid": "true",
      };
      await databaseChallenge.set(map);
      status = true;
      message = "Sucess";
    } catch (e) {
      status = false;
      message = "Error to save online: $e";
    }

    return Info(status: status, message: message);
  }

  static Future<Info> disconnectOnline({required UserApp userApp}) async {
    bool status = false;
    String message = "Iniciando";
    final FirebaseDatabase database = FirebaseDatabase.instance;
    final DatabaseReference databaseReference = database.ref().child('online/${userApp.uid}');
    final DatabaseReference databaseChallenge = database.ref().child('challenges/${userApp.uid}');

    try {
      await databaseReference.remove();
      await databaseChallenge.remove();
      status = true;
      message = "Sucess";
    } catch (e) {
      status = false;
      message = "Error to remove online: $e";
    }

    return Info(status: status, message: message);
  }

  //acepted challenge
  static Future<Info> acceptChallenge({required UserApp userApp, required UserApp userChallenge, required Puzzle puzzle}) async {
    bool status = false;
    String message = "Iniciando";
    final FirebaseDatabase database = FirebaseDatabase.instance;
    String path = 'challenges/${userChallenge.uid}/${userApp.uid}';
    final DatabaseReference databaseReference = database.ref().child(path);

    //puzzle.listTilesBytes = [];

    Map<String, dynamic> data = {
      'uid': userApp.uid,
      'name': userApp.name,
      'level': userApp.level,
      'points': userApp.points,
      'puzzle': puzzle.toJson(),
    };

    try {
      await databaseReference.update(data);
      status = true;
      message = "Sucess";
    } catch (e) {
      status = false;
      message = "Error to save: $e";
    }

    return Info(status: status, message: message);
  }

  //rejected challenge
  static rejectedChallenge({required UserApp userApp, required String idChallenge}) async {
    final FirebaseDatabase database = FirebaseDatabase.instance;
    String path = 'challenges/${userApp.uid}/${idChallenge}';
    final DatabaseReference databaseReference = database.ref().child(path);

    try {
      await databaseReference.remove();
    } catch (e) {
      print("Error to remove challenge: $e");
    }
  }

  //send moves to challenge
  static Future<Info> sendMovesChallenge({required Puzzle puzzle, required String uid, required String player}) async {
    bool status = false;
    String message = "Iniciando";
    final FirebaseDatabase database = FirebaseDatabase.instance;
    String path = 'moves/$uid/${player}';
    final DatabaseReference databaseReference = database.ref().child(path);

    try {
      await databaseReference.update(puzzle.toJson());
      status = true;
      message = "Sucess";
    } catch (e) {
      print("Error to save moves: $e");
      status = false;
      message = "Error to save moves: $e";
    }

    return Info(status: status, message: message);
  }

  static Future<Info> retireAndEnd({required String uid}) async {
    bool status = false;
    String message = "Iniciando";

    final FirebaseDatabase database = FirebaseDatabase.instance;
    String path = 'moves/$uid';
    final DatabaseReference databaseReference = database.ref().child(path);
    try {
      await databaseReference.remove();
      status = true;
      message = "Sucess";
    } catch (e) {
      print("Error to remove challenge: $e");
      status = false;
      message = "Error to remove challenge: $e";
    }

    return Info(status: status, message: message);
  }
}
