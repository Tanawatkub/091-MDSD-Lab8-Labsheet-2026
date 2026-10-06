import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryDummyJson implements ItemRepository {
  static const _baseUrl = 'https://dummyjson.com/products?limit=20';

  @override
  Future<List<Item>> getItems() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final products = jsonDecode(response.body)['products'] as List<dynamic>;
        return products.map((e) {
          final j = e as Map<String, dynamic>;
          return Item(
            id: j['id'] as int,
            title: j['title'] as String,
            price: (j['price'] as num).toDouble(),
            description: j['description'] as String,
            category: j['category'] as String,
            imageUrl: j['thumbnail'] as String,
          );
        }).toList();
      }
      throw Exception('ไม่สามารถโหลดรายการสินค้าได้ (สถานะ ${response.statusCode})');
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้');
    }
  }
}