import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/listing_draft.dart';
import '../repositories/listing_draft_repository.dart';
import '../services/gemini_vision_service.dart';
import 'my_drafts_page.dart';

enum AnalyzeStatus { idle, loading, success, error }

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;
  const SellItemPage({super.key, required this.draftRepository});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  // ขั้นตอน 6.1: แก้เฉพาะข้อความระหว่าง ''' ชั่วคราว แล้วเปลี่ยนกลับเป็นของเดิม
  static const String _prompt = '''
คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่เหมาะสมที่สุด เลือกจาก: หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์, ของแต่งหอพัก, เสื้อผ้า, อื่นๆ",
  "description": "คำบรรยายสินค้า 2-3 ประโยค ที่ดึงดูดผู้ซื้อและบอกสภาพของสินค้าตามที่เห็นในภาพ"
}
ห้ามตอบข้อความอื่นนอกเหนือจาก JSON ดังกล่าว
''';

  File? _image;
  AnalyzeStatus _status = AnalyzeStatus.idle;
  String _errorMessage = '';
  bool _isSaving = false;

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return; // ผู้ใช้กดยกเลิก
    setState(() {
      _image = File(picked.path);
      _status = AnalyzeStatus.idle; // เลือกรูปใหม่ ล้างผลเก่า
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });
  }

  Future<void> _analyze() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพสินค้าก่อน')),
      );
      return;
    }

    setState(() => _status = AnalyzeStatus.loading);

    try {
      final draft =
          await GeminiVisionService().analyzeProductImage(_image!, _prompt);
      if (!mounted) return;
      setState(() {
        _titleController.text = draft.title;
        _categoryController.text = draft.category;
        _descriptionController.text = draft.description;
        _status = AnalyzeStatus.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _status = AnalyzeStatus.error;
      });
    }
  }

  Future<void> _confirmDraft() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();
    final imagePath = _image?.path;
    final messenger = ScaffoldMessenger.of(context);

    // กันกรณีผู้ใช้ลบข้อความจนว่าง
    if (title.isEmpty || category.isEmpty || description.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบทั้ง 3 ช่อง')),
      );
      return;
    }
    if (imagePath == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('ไม่พบรูปภาพสินค้า กรุณาเลือกรูปใหม่')),
      );
      return;
    }

    // เก็บค่าจากฟอร์ม (ซึ่งอาจถูกแก้ไขแล้ว) เป็นร่างฉบับสุดท้าย
    final finalDraft = ListingDraft(
      title: title,
      category: category,
      description: description,
    );

    setState(() => _isSaving = true);
    try {
      await widget.draftRepository.saveDraft(finalDraft, imagePath);
      if (!mounted) return;
      setState(() {
        // ล้างฟอร์มกลับสู่สถานะว่าง พร้อมลงประกาศใหม่
        _image = null;
        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();
        _status = AnalyzeStatus.idle;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildResultSection() {
    switch (_status) {
      case AnalyzeStatus.idle:
        return const SizedBox.shrink();
      case AnalyzeStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('AI กำลังวิเคราะห์ภาพสินค้า...'),
            ],
          ),
        );
      case AnalyzeStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        );
      case AnalyzeStatus.success:
        return Column(
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อประกาศ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'คำบรรยาย',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _confirmDraft,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('ยืนยันร่างประกาศ'),
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _status == AnalyzeStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขายสินค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ร่างประกาศของฉัน',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MyDraftsPage(repository: widget.draftRepository),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.image, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: isLoading ? null : _analyze,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
            ),
            _buildResultSection(),
          ],
        ),
      ),
    );
  }
}