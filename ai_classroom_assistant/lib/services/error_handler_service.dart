import 'dart:async';
import 'dart:io';

class ErrorHandlerService {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);

  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = maxRetries,
    Duration delay = baseDelay,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        attempts++;
        
        if (attempts >= maxAttempts || (shouldRetry != null && !shouldRetry(error))) {
          rethrow;
        }
        
        // Exponential backoff
        final waitTime = delay * (attempts * attempts);
        await Future.delayed(waitTime);
      }
    }
    
    throw Exception('Max retry attempts exceeded');
  }

  static bool shouldRetryNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) {
      // Retry on server errors (5xx) but not client errors (4xx)
      return error.message.contains('500') || 
             error.message.contains('502') || 
             error.message.contains('503') || 
             error.message.contains('504');
    }
    if (error.toString().contains('Connection refused')) return true;
    if (error.toString().contains('Network is unreachable')) return true;
    return false;
  }

  static String getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'Network connection failed. Please check your internet connection.';
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is HttpException) {
      if (error.message.contains('401')) {
        return 'Invalid API key. Please check your credentials.';
      }
      if (error.message.contains('403')) {
        return 'Access denied. Please verify your API key permissions.';
      }
      if (error.message.contains('429')) {
        return 'Rate limit exceeded. Please wait a moment and try again.';
      }
      if (error.message.contains('500')) {
        return 'Server error. Please try again later.';
      }
    }
    if (error.toString().contains('Failed to extract topics')) {
      return 'Unable to extract topics. Please check your transcription and try again.';
    }
    if (error.toString().contains('Failed to generate notes')) {
      return 'Unable to generate notes. Please try again or check your API key.';
    }
    if (error.toString().contains('Failed to get topic details')) {
      return 'Unable to load topic details. Please try again.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  static bool isNetworkError(dynamic error) {
    return error is SocketException || 
           error is TimeoutException ||
           error.toString().contains('Connection refused') ||
           error.toString().contains('Network is unreachable');
  }

  static bool isAPIKeyError(dynamic error) {
    return error.toString().contains('401') || 
           error.toString().contains('403') ||
           error.toString().contains('Invalid API key') ||
           error.toString().contains('Access denied');
  }

  static bool isRateLimitError(dynamic error) {
    return error.toString().contains('429') ||
           error.toString().contains('Rate limit') ||
           error.toString().contains('Too many requests');
  }
}