import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryDrift implements FavoritesRepository {
  final AppDatabase _db;
  FavoritesRepositoryDrift(this._db);

  @override
  Future<void> addFavorite(
      int itemId, String title, double price, String imageUrl) {
    return _db.into(_db.favoriteItems).insert(
          FavoriteItemsCompanion.insert(
            itemId: itemId,
            title: title,
            price: price,
            imageUrl: imageUrl,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<List<FavoriteItem>> getAllFavorites() {
    return (_db.select(_db.favoriteItems)
          ..orderBy([(t) => OrderingTerm.desc(t.addedAt)]))
        .get();
  }

  @override
  Future<void> removeFavorite(int itemId) {
    return (_db.delete(_db.favoriteItems)
          ..where((t) => t.itemId.equals(itemId)))
        .go();
  }
}