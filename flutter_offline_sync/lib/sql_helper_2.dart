import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLHelper {
  static Database? database;
  static const String tableName = 'tb_user_flutter_offline';

  // CREATE TABLE
  static Future<void> createTables(Database database) async {
    await database.execute("""CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      nama_user TEXT,
      alamat TEXT,
      waktu_simpan_data TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    """);
  }

  // CEK APAKAH ADA TABLE
  static Future<bool> isTableExists() async {
    final db = database;
    final result = await db?.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'");
    return result?.isNotEmpty ?? false;
  }

  // MEMBUAT DATABASE
  static Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'db_offline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // MEMBUAT TABLE
        await createTables(db);
      },
    );
  }

  // MENGHAPUS TABLE
  static Future<void> deleteTable() async {
    if (database != null) {
      await database!.transaction((txn) async {
        await txn.execute('DROP TABLE IF EXISTS $tableName');
      });
    }
  }

  // MENDAPATKAN LIST ITEM
  static Future<List<Map<String, dynamic>>> getItem() async {
    final db = database;
    final List<Map<String, dynamic>> items = await db?.query(tableName) ?? [];
    return items;
  }

  // MENAMBAH ITEM
  static Future<int> addItem(String namaUser, String alamatUser) async {
    final db = database;
    final data = {
      'nama_user': namaUser,
      'alamat': alamatUser,
    };
    final id = await db?.insert(tableName, data,
            conflictAlgorithm: ConflictAlgorithm.replace) ??
        0;
    return id;
  }

  // MENGUPDATE ITEM
  static Future<int> updateItem(
      int id, String namaUser, String alamatUser) async {
    final db = database;
    final data = {
      'nama_user': namaUser,
      'alamat': alamatUser,
      'waktu_simpan_data': DateTime.now().toString()
    };
    final dataRowTerbaru = await db?.update(
          tableName,
          data,
          where: 'id = ?',
          whereArgs: [id],
        ) ??
        0;
    return dataRowTerbaru;
  }

  // MENGHAPUS ITEM
  static Future<void> deleteItem(int id) async {
    final db = database;
    await db?.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // MENGHAPUS SEMUA ITEM
  static Future<void> deleteAllItems() async {
    final db = database;
    await db!.delete(tableName);
  }
}
