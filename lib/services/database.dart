import 'dart:async';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'notification.dart';

class DBHelper {
  static Database? _db;
  static const String NO = 'no';
  static const String ID = 'id';
  static const String NOTI = 'noti';
  static const String TIME  = 'time';
  static const String TABLE = 'Notification';
  static const String DB_NAME = 'Notification.db';

  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();
    return _db;
  }

  initDb() async {  //init db
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, DB_NAME);
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  _onCreate(Database db, int version) async { //t?o database
    await db
        .execute("CREATE TABLE $TABLE ($NO INTEGER PRIMARY KEY, $ID TEXT, $NOTI TEXT,$TIME TEXT)");
  }

  Future<Notifications> save(Notifications noti) async {  // insert employee v o b?ng don gi?n
    var dbClient = await db;
    noti.no = await dbClient!.insert(TABLE, noti.toMap());
    return noti;
    /*
    await dbClient.transaction((txn) async {
      var query = "INSERT INTO $TABLE ($NAME) VALUES ('" + employee.name + "')";
      return await txn.rawInsert(query); //c c b?n c  th? s? d?ng rawQuery n?u truy v?n ph?c t?p d? thay th? cho c c phu?c th?c c  s?n c?a l?p Database.
    });
    */
  }

  Future<List<Notifications>> getNotifications() async {  //get list employees don gi?n
    var dbClient = await db;
    List<Map> maps = await dbClient!.query(TABLE, columns: [NO, ID, NOTI, TIME]);
    //List<Map> maps = await dbClient.rawQuery("SELECT * FROM $TABLE");
    List<Notifications> notifications = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        notifications.add(Notifications.fromMap(maps[i]));
      }
    }
    return notifications;
  }

  Future<int> delete(int no) async { // x a employee
    var dbClient = await db;
    return await dbClient!.delete(TABLE, where: '$NO = ?', whereArgs: [no]); //where - x a t?i ID n o, whereArgs - argument l  g ?
  }

  Future<int> update(Notifications notifications) async {
    var dbClient = await db;
    return await dbClient!.update(TABLE, notifications.toMap(),
        where: '$NO = ?', whereArgs: [notifications.no]);
  }

  Future close() async { //close khi kh ng s? d?ng
    var dbClient = await db;
    dbClient!.close();
  }
}
