import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import 'checkout_page.dart';
import '../services/gemini_service.dart';

class HomePage extends StatefulWidget {
  final ItemRepository repository;
  final FavoritesRepository favoritesRepository;
  const HomePage({
    super.key,
    required this.repository,
    required this.favoritesRepository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.repository.getItems();
  }

  Future<void> _addToFavorites(Item item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.favoritesRepository.addFavorite(
        item.id,
        item.title,
        item.price,
        item.imageUrl,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('เพิ่ม "${item.title}" ในรายการโปรดแล้ว')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          // ปุ่มทดสอบชั่วคราว (ลบทิ้งหลังทำ Checkpoint 2.1 เสร็จ)
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final text = await GeminiService().generateText(
                  'ช่วยแต่งประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง',
                );
                debugPrint('Gemini: $text');
                messenger.showSnackBar(SnackBar(content: Text(text)));
              } catch (e) {
                debugPrint('Error: $e');
                messenger.showSnackBar(SnackBar(content: Text('$e')));
              }
            },
          ),
          IconButton(
            icon: Badge(
              label: Text('${context.watch<CartModel>().itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('ไม่พบสินค้า'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Image.network(
                  item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
                title: Text(item.title),
                subtitle: Text('${item.price} บาท'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () => _addToFavorites(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        context.read<CartModel>().add(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('เพิ่ม "${item.title}" ลงตะกร้าแล้ว')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}