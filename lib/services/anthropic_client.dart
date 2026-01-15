import 'package:dio/dio.dart';
import 'dart:convert';

/// Client for interacting with Anthropic Claude API
/// Provides methods for chat completion with error handling
class AnthropicClient {
  final Dio dio;

  // Model constants - using Claude Sonnet 4.5 for optimal performance
  static const String defaultModel = 'claude-sonnet-4-5-20250929';
  static const String sonnet45 = 'claude-sonnet-4-5-20250929';
  static const String haiku45 = 'claude-haiku-4-5-20251001';

  AnthropicClient(this.dio);

  /// Creates a chat completion request with Claude
  /// Returns the AI-generated response text
  Future<Completion> createChat({
    required List<Message> messages,
    String model = defaultModel,
    int maxTokens = 2048,
    double temperature = 1.0,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.post(
        '/messages',
        data: {
          'model': model,
          'max_tokens': maxTokens,
          'messages': messages
              .map(
                (m) => {
                  'role': m.role,
                  'content': m.content is String ? m.content : m.content,
                },
              )
              .toList(),
          if (temperature != 1.0) 'temperature': temperature,
        },
        cancelToken: cancelToken,
      );

      final text = response.data['content'][0]['text'];
      return Completion(text: text);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw AnthropicException(
          statusCode: 499,
          message: 'Request was cancelled by user',
          isInternal: false,
        );
      }
      throw _handleDioException(e);
    }
  }

  /// Streams chat completion responses for real-time updates
  /// Yields text chunks as they arrive from Claude
  Stream<String> streamChat({
    required List<Message> messages,
    String model = defaultModel,
    int maxTokens = 2048,
    double temperature = 1.0,
    CancelToken? cancelToken,
  }) async* {
    try {
      final response = await dio.post(
        '/messages',
        data: {
          'model': model,
          'max_tokens': maxTokens,
          'messages': messages
              .map(
                (m) => {
                  'role': m.role,
                  'content': m.content is String ? m.content : m.content,
                },
              )
              .toList(),
          'stream': true,
          if (temperature != 1.0) 'temperature': temperature,
        },
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      final stream = response.data as ResponseBody;
      await for (var line in LineSplitter().bind(
        utf8.decoder.bind(stream.stream),
      )) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            if (json['type'] == 'content_block_delta') {
              final text = json['delta']['text'];
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            }
          } catch (_) {
            // Skip malformed JSON chunks
            continue;
          }
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw AnthropicException(
          statusCode: 499,
          message: 'Request was cancelled by user',
          isInternal: false,
        );
      }
      throw _handleDioException(e);
    }
  }

  /// Centralized error handling for Dio exceptions
  AnthropicException _handleDioException(DioException e) {
    final statusCode = e.response?.statusCode ?? 500;
    final errorMessage =
        e.response?.data?['error']?['message'] ??
        e.message ??
        'An unexpected error occurred';
    final errorType = e.response?.data?['error']?['type'] ?? '';

    // Determine if error is internal (service/auth issue) or fixable (code issue)
    bool isInternal = false;

    if (statusCode == 401 || errorType == 'authentication_error') {
      isInternal = true;
    } else if (statusCode == 403 || errorType == 'permission_error') {
      isInternal = true;
    } else if (statusCode == 404 || errorType == 'not_found_error') {
      isInternal = true;
    } else if (statusCode == 429 || errorType == 'rate_limit_error') {
      isInternal = true;
    } else if (statusCode >= 500 || errorType == 'api_error') {
      isInternal = true;
    } else if (statusCode == 529 || errorType == 'overloaded_error') {
      isInternal = true;
    }

    return AnthropicException(
      statusCode: statusCode,
      message: _getUserFriendlyErrorMessage(
        statusCode,
        errorType,
        errorMessage,
      ),
      isInternal: isInternal,
    );
  }

  String _getUserFriendlyErrorMessage(
    int statusCode,
    String errorType,
    String originalMessage,
  ) {
    if (statusCode == 401 || errorType == 'authentication_error') {
      return 'Invalid API key or authentication failed. Please check your Anthropic API key.';
    } else if (statusCode == 403 || errorType == 'permission_error') {
      return 'Access forbidden. You may not have permission to access this resource or feature.';
    } else if (statusCode == 404 || errorType == 'not_found_error') {
      return 'Resource not found. The requested endpoint or model may not exist.';
    } else if (statusCode == 429 || errorType == 'rate_limit_error') {
      return 'Rate limit exceeded. Please wait a moment and try again.';
    } else if (statusCode >= 500 || errorType == 'api_error') {
      return 'Anthropic service is currently unavailable. Please try again later.';
    } else if (statusCode == 529 || errorType == 'overloaded_error') {
      return 'Anthropic service is temporarily overloaded. Please try again shortly.';
    }

    return originalMessage;
  }
}

/// Represents a chat message with role and content
class Message {
  final String role;
  final dynamic content; // String or List<Map<String, dynamic>>

  Message({required this.role, required this.content});
}

/// Represents a completed AI response
class Completion {
  final String text;

  Completion({required this.text});
}

/// Custom exception for Anthropic API errors
class AnthropicException implements Exception {
  final int statusCode;
  final String message;
  final bool isInternal;

  AnthropicException({
    required this.statusCode,
    required this.message,
    required this.isInternal,
  });

  @override
  String toString() =>
      'AnthropicException: $statusCode - $message (isInternal: $isInternal)';
}
