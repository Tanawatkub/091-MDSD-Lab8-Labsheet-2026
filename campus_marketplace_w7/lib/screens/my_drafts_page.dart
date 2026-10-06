import 'dart:io';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../repositories/listing_draft_repository.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;
  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _draftsFuture = widget.repository.getAllDrafts();
  }

  Future<void> _delete(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.deleteDraft(id);
      if (!mounted) return;
      setState(() {
        _draftsFuture = widget.repository.getAllDrafts();
      });
      messenger.showSnackBar(const SnackBar(content: Text('ลบร่างประกาศแล้ว')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร่างประกาศของฉัน')),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีร่างประกาศ ลองสร้างที่แท็บ "ลงประกาศขาย" ดูสิ'),
            );
          }
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final d = drafts[index];
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.file(
                    File(d.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
                title: Text(d.title),
                subtitle: Text('${d.category}\nแก้ไขล่าสุด ${_formatDate(d.updatedAt)}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _delete(d.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}