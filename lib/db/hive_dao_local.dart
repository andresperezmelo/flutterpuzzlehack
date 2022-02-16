import 'package:hive_flutter/hive_flutter.dart';

class HiveDaoLocal {
  static Future<void> setData({required String id, required Map<String, dynamic> data}) async {
    final db = await Hive.openBox('local');
    db.put(id, data);
  }

  static Future<Map<String, dynamic>> getData({required String id}) async {
    final Box db = await Hive.openBox('local');
    Map<String, dynamic> data = {};
    if (db.containsKey(id)) {
      Map<dynamic, dynamic> map = db.get(id);
      data = map.cast<String, dynamic>();
    }
    return data;
  }

  static Future<int> clearData() async {
    final db = await Hive.openBox('local');
    return db.clear();
  }
}
