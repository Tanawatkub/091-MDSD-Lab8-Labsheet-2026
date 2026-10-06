import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository repository;
  const FavoritesPage({super.key, required this.repository});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteItem>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = widget.repository.getAllFavorites();
  }

  void _reload() {
    setState(() {
      _favoritesFuture = widget.repository.getAllFavorites();
    });
  }

  Future<void> _remove(FavoriteItem fav) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.removeFavorite(fav.itemId);
      messenger.showSnackBar(
        SnackBar(content: Text('ลบ "${fav.title}" ออกจากรายการโปรดแล้ว')),
      );
      _reload();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
      body: FutureBuilder<List<FavoriteItem>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ'),
            );
          }
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return ListTile(
                leading: Image.network(
                  fav.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
                title: Text(fav.title),
                subtitle: Text('${fav.price} บาท'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _remove(fav),
                ),
              );
            },
          );
        },
      ),
    );
  }
}