import 'dart:async';

import 'package:flutter/foundation.dart';

/// Service for managing quiz timer
class QuizTimerService extends ChangeNotifier {
  Timer? _timer;
  int _remainingTimeInSeconds = 0;
  DateTime? _startTime;
  bool _isRunning = false;
  bool _disposed = false;

  VoidCallback? _onTimerComplete;

  // Getters
  int get remainingTimeInSeconds => _remainingTimeInSeconds;
  bool get isRunning => _isRunning;
  DateTime? get startTime => _startTime;

  /// Initialize timer with duration in minutes
  void initialize(int durationInMinutes, {VoidCallback? onComplete}) {
    _remainingTimeInSeconds = durationInMinutes * 60;
    _onTimerComplete = onComplete;
    _startTime = DateTime.now();
  }

  /// Start the timer
  void start() {
    if (_isRunning || _disposed) return;

    _isRunning = true;
    _startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Always check disposed first
      if (_disposed) {
        timer.cancel();
        _isRunning = false;
        return;
      }

      if (_remainingTimeInSeconds > 0) {
        _remainingTimeInSeconds--;
        notifyListeners();
      } else {
        // Timer completed
        _isRunning = false;
        timer.cancel();
        _timer = null;

        // Call completion callback
        final callback = _onTimerComplete;
        if (callback != null && !_disposed) {
          // Schedule callback for next frame to avoid calling during build
          Future.microtask(() {
            if (!_disposed) {
              callback();
            }
          });
        }
      }
    });
  }

  /// Stop the timer
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Pause the timer
  void pause() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    notifyListeners();
  }

  /// Resume the timer
  void resume() {
    if (_remainingTimeInSeconds <= 0) return;
    start();
  }

  /// Reset timer to initial duration
  void reset(int durationInMinutes) {
    stop();
    _remainingTimeInSeconds = durationInMinutes * 60;
    _startTime = DateTime.now();
    notifyListeners();
  }

  /// Calculate elapsed time
  Duration getElapsedTime(int totalDurationInMinutes) {
    final totalSeconds = totalDurationInMinutes * 60;
    final elapsedSeconds = totalSeconds - _remainingTimeInSeconds;
    return Duration(seconds: elapsedSeconds);
  }

  /// Update remaining time (useful for loading saved progress)
  void updateRemainingTime(int seconds) {
    _remainingTimeInSeconds = seconds;
    if (!_disposed) {
      notifyListeners();
    }
  }

  /// Format remaining time as MM:SS
  String get formattedTime {
    final minutes = _remainingTimeInSeconds ~/ 60;
    final seconds = _remainingTimeInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
