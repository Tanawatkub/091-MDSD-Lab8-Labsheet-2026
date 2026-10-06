import 'package:flutter/material.dart';
import 'home_page.dart';
import 'sell_item_page.dart';
import 'favorites_page.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/listing_draft_repository.dart';

class MainScaffold extends StatefulWidget {
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;
  const MainScaffold({
    super.key,
    required this.itemRepository,
    required this.favoritesRepository,
    required this.draftRepository,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  int _favoritesVersion = 0; // เพิ่มค่าทุกครั้งที่สลับมา Tab รายการโปรด

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        repository: widget.itemRepository,
        favoritesRepository: widget.favoritesRepository,
      ),
      SellItemPage(draftRepository: widget.draftRepository),
      FavoritesPage(
        key: ValueKey(_favoritesVersion),
        repository: widget.favoritesRepository,
      ),
    ];

    return Scaffold(
      // IndexedStack เก็บ State ของทุก Tab ไว้ สลับ Tab แล้วรูปที่เลือกไม่หาย
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() {
          if (index == 2) _favoritesVersion++; // สร้าง FavoritesPage ใหม่ → โหลดข้อมูลล่าสุด
          _selectedIndex = index;
        }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'รายการโปรด'),
        ],
      ),
    );
  }
}