import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiApiKeyNotifier extends AsyncNotifier<String> {
  static const _key = 'gemini_api_key';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '';
  }

  Future<void> set(String value) async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, value);
    }
    state = AsyncValue.data(value);
  }
}

final geminiApiKeyProvider =
    AsyncNotifierProvider<GeminiApiKeyNotifier, String>(
        GeminiApiKeyNotifier.new);
