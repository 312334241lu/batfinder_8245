import 'package:dio/dio.dart';

/// Service for managing Anthropic API integration
/// Provides singleton Dio client with proper authentication and configuration
class AnthropicService {
  static final AnthropicService _instance = AnthropicService._internal();
  late final Dio _dio;
  static const String apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  factory AnthropicService() {
    return _instance;
  }

  AnthropicService._internal() {
    _initializeService();
  }

  void _initializeService() {
    if (apiKey.isEmpty) {
      throw Exception('ANTHROPIC_API_KEY must be provided via --dart-define');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.anthropic.com/v1',
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
  }

  Dio get dio => _dio;
  String get authApiKey => apiKey;
}
