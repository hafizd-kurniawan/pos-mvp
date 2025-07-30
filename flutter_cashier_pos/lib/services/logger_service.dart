import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  // Enable/disable logging based on build mode
  bool get isLoggingEnabled => kDebugMode || !kReleaseMode;

  void debug(String message, {String? tag, dynamic data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  void info(String message, {String? tag, dynamic data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  void warning(String message, {String? tag, dynamic data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, data: error);
    if (stackTrace != null && isLoggingEnabled) {
      developer.log(
        'StackTrace: $stackTrace',
        name: tag ?? 'LoggerService',
        level: _getLogLevelValue(LogLevel.error),
      );
    }
  }

  void critical(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, tag: tag, data: error);
    if (stackTrace != null && isLoggingEnabled) {
      developer.log(
        'StackTrace: $stackTrace',
        name: tag ?? 'LoggerService',
        level: _getLogLevelValue(LogLevel.critical),
      );
    }
  }

  // Specific methods for common scenarios
  void apiCall(String endpoint, {String method = 'GET', dynamic requestData}) {
    if (isLoggingEnabled) {
      info('API Call: $method $endpoint', tag: 'API', data: requestData);
    }
  }

  void apiResponse(String endpoint, int statusCode, {dynamic responseData, Duration? duration}) {
    if (isLoggingEnabled) {
      final durationText = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      info('API Response: $endpoint - $statusCode$durationText', tag: 'API', data: responseData);
    }
  }

  void apiError(String endpoint, dynamic error, {StackTrace? stackTrace}) {
    this.error('API Error: $endpoint', tag: 'API', error: error, stackTrace: stackTrace);
  }

  void navigationEvent(String from, String to) {
    debug('Navigation: $from → $to', tag: 'Navigation');
  }

  void userAction(String action, {dynamic data}) {
    info('User Action: $action', tag: 'UserAction', data: data);
  }

  void businessLogic(String operation, {dynamic data}) {
    debug('Business Logic: $operation', tag: 'Business', data: data);
  }

  void uiError(String widget, String error, {StackTrace? stackTrace}) {
    this.error('UI Error in $widget: $error', tag: 'UI', error: error, stackTrace: stackTrace);
  }

  void performanceWarning(String operation, Duration duration) {
    if (duration.inMilliseconds > 1000) {
      warning('Performance Warning: $operation took ${duration.inMilliseconds}ms', tag: 'Performance');
    }
  }

  void _log(LogLevel level, String message, {String? tag, dynamic data}) {
    if (!isLoggingEnabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelString = level.name.toUpperCase();
    final tagString = tag ?? 'App';
    
    String logMessage = '[$timestamp] [$levelString] [$tagString] $message';
    
    if (data != null) {
      logMessage += '\nData: $data';
    }

    // Use dart:developer log for better formatting in Flutter DevTools
    developer.log(
      logMessage,
      name: tagString,
      level: _getLogLevelValue(level),
      time: DateTime.now(),
    );

    // Also print for console visibility during development
    if (kDebugMode) {
      print(logMessage);
    }
  }

  int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }

  // Utility method to measure and log execution time
  Future<T> measureTime<T>(
    String operation, 
    Future<T> Function() function, {
    String? tag,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      
      final duration = stopwatch.elapsed;
      debug('$operation completed in ${duration.inMilliseconds}ms', tag: tag ?? 'Performance');
      performanceWarning(operation, duration);
      
      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();
      this.error('$operation failed after ${stopwatch.elapsed.inMilliseconds}ms', 
                tag: tag ?? 'Performance', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Log app lifecycle events
  void appLifecycle(String event) {
    info('App Lifecycle: $event', tag: 'Lifecycle');
  }

  // Log authentication events
  void authEvent(String event, {String? userId}) {
    info('Auth Event: $event${userId != null ? ' (User: $userId)' : ''}', tag: 'Auth');
  }

  // Log data persistence events
  void dataEvent(String operation, String type, {String? id}) {
    debug('Data $operation: $type${id != null ? ' (ID: $id)' : ''}', tag: 'Data');
  }
}

// Global logger instance for easy access
final logger = LoggerService();