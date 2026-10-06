import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/app_database.dart';
import 'models/cart_model.dart';
import 'screens/main_scaffold.dart';
import 'repositories/item_repository_dummyjson.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';


void main() {
  // สร้าง AppDatabase ครั้งเดียว แล้วส่งต่อผ่าน Constructor
  final db = AppDatabase();

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      home: MainScaffold(
        itemRepository: ItemRepositoryDummyJson(),
        favoritesRepository: FavoritesRepositoryDrift(db),
        draftRepository: ListingDraftRepositoryDrift(db),
      ),
    );
  }
}