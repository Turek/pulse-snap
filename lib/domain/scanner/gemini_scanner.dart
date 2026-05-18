import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/scan_result.dart';
import 'i_scanner.dart';

/// Sends the captured image to Google's Gemini Flash and asks for a
/// structured JSON object containing the three BP values. Works on any
/// 7-segment display because the vision model handles digit recognition
/// trivially.
///
/// Authentication: API key stored client-side in shared_preferences. This
/// is fine for personal/MVP use — swap to a backend proxy before any
/// public distribution so the key isn't shipped with the APK/IPA.
class GeminiFlashScanner extends IScanner {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const _prompt =
      'You are reading a blood pressure monitor display. Extract the three '
      'numeric readings: systolic (mmHg), diastolic (mmHg), and pulse rate '
      '(bpm). Use null for any value not clearly visible. Return ONLY a JSON '
      'object matching the schema. No prose.';

  final String apiKey;
  final Dio _dio;

  GeminiFlashScanner({required this.apiKey, Dio? dio})
      : _dio = dio ?? Dio();

  @override
  ScannerType get type => ScannerType.geminiFlash;

  @override
  Future<ScanResult> scan(File imageFile) async {
    if (apiKey.isEmpty) {
      return const ScanResult(
        confidence: 0.0,
        source: ScannerType.geminiFlash,
        debugInfo: 'Gemini: no API key set',
      );
    }
    final bytes = await imageFile.readAsBytes();
    final b64 = base64Encode(bytes);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_endpoint?key=$apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {'text': _prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': b64,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.0,
            'responseMimeType': 'application/json',
            'responseSchema': {
              'type': 'object',
              'properties': {
                'systolic': {'type': 'integer', 'nullable': true},
                'diastolic': {'type': 'integer', 'nullable': true},
                'pulse': {'type': 'integer', 'nullable': true},
              },
            },
          },
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final candidates =
          response.data?['candidates'] as List<dynamic>? ?? const [];
      if (candidates.isEmpty) {
        debugPrint('[Gemini] empty candidates: ${response.data}');
        return const ScanResult(
          confidence: 0.0,
          source: ScannerType.geminiFlash,
          debugInfo: 'Gemini: empty response',
        );
      }
      final text = candidates[0]?['content']?['parts']?[0]?['text'] as String?;
      if (text == null) {
        return const ScanResult(
          confidence: 0.0,
          source: ScannerType.geminiFlash,
          debugInfo: 'Gemini: no text part',
        );
      }
      debugPrint('[Gemini] raw=$text');
      final parsed = jsonDecode(text) as Map<String, dynamic>;
      final sys = parsed['systolic'] as int?;
      final dia = parsed['diastolic'] as int?;
      final pulse = parsed['pulse'] as int?;
      return ScanResult(
        systolic: sys,
        diastolic: dia,
        pulse: pulse,
        confidence: 0.95,
        source: ScannerType.geminiFlash,
        debugInfo: 'gemini: $text',
      );
    } on DioException catch (e) {
      debugPrint(
        '[Gemini] HTTP error: ${e.response?.statusCode} ${e.response?.data}',
      );
      return ScanResult(
        confidence: 0.0,
        source: ScannerType.geminiFlash,
        debugInfo:
            'Gemini HTTP ${e.response?.statusCode}: ${e.response?.data ?? e.message}',
      );
    } catch (e) {
      debugPrint('[Gemini] error: $e');
      return ScanResult(
        confidence: 0.0,
        source: ScannerType.geminiFlash,
        debugInfo: 'Gemini error: $e',
      );
    }
  }
}
