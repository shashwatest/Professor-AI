// lib/services/utils/backoff.dart
import 'dart:async';
import 'dart:math';

/// Generic exponential backoff with jitter
Future<T> withExponentialBackoff<T>(
  Future<T> Function() fn, {
  int maxAttempts = 5,
  int initialDelayMs = 500,
  double multiplier = 2.0,
}) async {
  final rand = Random();
  var attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (e) {
      attempt++;
      if (attempt >= maxAttempts) rethrow;
      final delayMs = (initialDelayMs * pow(multiplier, attempt - 1)).toInt();
      // jitter 0..delayMs/2
      final jitter = rand.nextInt(delayMs ~/ 2 + 1);
      final wait = Duration(milliseconds: delayMs + jitter);
      await Future.delayed(wait);
    }
  }
}
