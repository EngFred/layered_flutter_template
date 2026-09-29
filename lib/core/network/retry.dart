import 'dart:math';

import '../error/failure.dart';
import '../error/result.dart';

/// Runs [action] up to [maxAttempts] times with exponential backoff plus
/// jitter. Returns the first `Ok`, or the last `Err` if every attempt fails.
///
/// Failures that will never succeed on retry are short-circuited:
///   - [AuthFailure]            — credentials or token problems
///   - [ParsingFailure]         — server contract changed
///   - [StorageFailure]         — local disk problem
///   - [ServerFailure] with 4xx — client error; the server is telling us no
///
/// Everything else (timeouts, 5xx, network) gets retried.
Future<Result<T>> withRetry<T>(
  Future<Result<T>> Function() action, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 500),
  Duration maxDelay = const Duration(seconds: 8),
  Random? random,
}) async {
  assert(maxAttempts >= 1, 'maxAttempts must be at least 1');
  final rng = random ?? Random();
  var delay = initialDelay;
  Result<T>? last;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    last = await action();
    if (last is Ok<T>) return last;

    if (!_isRetryable(last as Err<T>)) return last;
    if (attempt == maxAttempts) break;

    // ±25% jitter so simultaneous clients don't retry in lockstep.
    final baseMs = delay.inMilliseconds;
    final jitterMs = (baseMs * 0.25 * (rng.nextDouble() * 2 - 1)).round();
    await Future<void>.delayed(
      Duration(milliseconds: max(0, baseMs + jitterMs)),
    );
    delay = Duration(milliseconds: min(baseMs * 2, maxDelay.inMilliseconds));
  }
  return last!;
}

bool _isRetryable<T>(Err<T> err) {
  final f = err.failure;
  if (f is AuthFailure) return false;
  if (f is ParsingFailure) return false;
  if (f is StorageFailure) return false;
  if (f is ServerFailure) {
    final code = f.statusCode ?? 500;
    return code >= 500;
  }
  // Network, timeout, unexpected — all worth a second try.
  return true;
}
