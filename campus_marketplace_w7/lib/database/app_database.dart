import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart'; // เติมเพิ่มจากบทเรียน

part 'app_database.g.dart'; // ไฟล์นี้ build_runner จะสร้างให้

@DriftDatabase(tables: [FavoriteItems, ListingDrafts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'campus_marketplace.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}