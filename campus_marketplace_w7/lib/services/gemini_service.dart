import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _model = 'gemini-3.5-flash-lite';  // ตามบทเรียน 7.3 (ถ้าเจอ 404 ลอง gemini-3.8-flash หรือ gemini-3.5-flash-lite)
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  Future<String> generateText(String prompt) async {
    if (_apiKey.isEmpty) {
      throw Exception('ไม่พบ GEMINI_API_KEY กรุณารันด้วย --dart-define');
    }

    final uri = Uri.parse('$_baseUrl?key=$_apiKey');
    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 429) {
        throw Exception('ใช้งานเกินโควตาที่กำหนดในขณะนี้ กรุณาลองใหม่ภายหลัง');
      }
      if (response.statusCode != 200) {
        throw Exception(
            'เซิร์ฟเวอร์ Gemini ตอบกลับผิดพลาด (รหัส ${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // ตรวจว่า candidates มีข้อมูลจริง (Status 200 ไม่ได้แปลว่ามีคำตอบเสมอไป)
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini ไม่สามารถสร้างคำตอบได้ในครั้งนี้');
      }

      final candidate = candidates.first as Map<String, dynamic>;
      if (candidate['finishReason'] == 'SAFETY') {
        throw Exception('เนื้อหาเข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini');
      }

      final parts = candidate['content']?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('รูปแบบคำตอบจาก AI ไม่ถูกต้อง');
      }

      return parts.first['text'] as String;
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้');
    } on FormatException {
      throw Exception('ข้อมูลที่ได้รับไม่ถูกต้อง');
    }
  }
}