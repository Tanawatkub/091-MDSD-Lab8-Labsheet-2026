import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/listing_draft.dart';

class GeminiVisionService {
  static const _model = 'gemini-3.5-flash-lite'; // ถ้าเจอ 404/503 ลอง gemini-3.8-flash หรือ gemini-3.5-flash-lite
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  String _mimeType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<ListingDraft> analyzeProductImage(File imageFile, String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('ไม่พบ GEMINI_API_KEY กรุณารันด้วย --dart-define');
    }

    // 1) อ่านไฟล์ภาพเป็นไบต์ แล้วเข้ารหัส Base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // 2) ส่งภาพ + Prompt ใน parts เดียวกัน และบังคับ JSON ด้วย responseSchema
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': _mimeType(imageFile.path),
                'data': base64Image,
              },
            },
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'category': {'type': 'STRING'},
            'description': {'type': 'STRING'},
          },
          'required': ['title', 'category', 'description'],
        },
      },
      // [เพิ่มใหม่ ส่วนที่ 6] ตั้งตัวกรองความปลอดภัยให้เข้มที่สุด
      // ผ่อนเป็น BLOCK_MEDIUM_AND_ABOVE ได้ ถ้าเข้มเกินจนภาพปกติถูกบล็อก
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_LOW_AND_ABOVE'},
      ],
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 429) {
        throw Exception('ใช้งานเกินโควตาที่กำหนดในขณะนี้ กรุณาลองใหม่ภายหลัง');
      }
      if (response.statusCode != 200) {
        throw Exception(
            'เซิร์ฟเวอร์ Gemini ตอบกลับผิดพลาด (รหัส ${response.statusCode})');
      }

      // 3) jsonDecode ชั้นที่ 1: ถอด response ของ API
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // [เพิ่มใหม่ ส่วนที่ 6] Prompt ถูกบล็อกตั้งแต่ต้นทาง (ไม่มี candidates)
      final blockReason = data['promptFeedback']?['blockReason'];
      if (blockReason != null) {
        throw Exception(
            'คำขอถูกบล็อกด้วยระบบความปลอดภัยของ Gemini ($blockReason)');
      }

      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น');
      }

      final candidate = candidates.first as Map<String, dynamic>;

      // [ปรับ ส่วนที่ 6] ครอบคลุม finishReason ที่เกี่ยวกับความปลอดภัยหลายแบบ
      const blockedReasons = {'SAFETY', 'PROHIBITED_CONTENT', 'BLOCKLIST', 'SPII'};
      if (blockedReasons.contains(candidate['finishReason'])) {
        throw Exception('เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น');
      }

      final parts = candidate['content']?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('รูปแบบคำตอบจาก AI ไม่ถูกต้อง');
      }

      // ข้ามส่วน "thought" (ถ้ามี) แล้วเอาข้อความจริง
      final textPart = parts.cast<Map<String, dynamic>>().firstWhere(
            (p) => p['text'] != null && p['thought'] != true,
            orElse: () => throw Exception('AI ไม่ได้ส่งข้อความตอบกลับมา'),
          );

      // 4) jsonDecode ชั้นที่ 2: ถอดข้อความ JSON ที่อยู่ใน text
      final draftJson = jsonDecode(textPart['text'] as String) as Map<String, dynamic>;
      return ListingDraft.fromJson(draftJson);
    } on TimeoutException {
      throw Exception('AI ใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
    } on SocketException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้');
    } on FormatException {
      throw Exception('ข้อมูลที่ได้รับจาก AI ไม่ถูกต้อง กรุณาลองใหม่');
    } on TypeError {
      throw Exception('โครงสร้างข้อมูลจาก AI ไม่ครบ กรุณาลองใหม่');
    }
  }
}