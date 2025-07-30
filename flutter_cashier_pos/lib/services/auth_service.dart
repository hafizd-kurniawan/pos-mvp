import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import 'logger_service.dart';

class AuthService {
  final Box _authBox = Hive.box(AppConstants.authBox);
  final LoggerService _logger = logger;

  // Check if user is logged in
  bool isLoggedIn() {
    final token = _authBox.get(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Get current user data
  User? getCurrentUser() {
    final userData = _authBox.get(AppConstants.userKey);
    if (userData != null) {
      return User.fromJson(Map<String, dynamic>.from(userData));
    }
    return null;
  }

  // Get stored JWT token
  String? getToken() {
    return _authBox.get(AppConstants.tokenKey);
  }

  // Login user
  Future<Map<String, dynamic>> login(String username, String password) async {
    _logger.authEvent('Login attempt', userId: username);
    
    try {
      final stopwatch = Stopwatch()..start();
      _logger.apiCall(AppConstants.authEndpoint, method: 'POST', requestData: {
        'username': username,
        'password': '[HIDDEN]'
      });

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.authEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      stopwatch.stop();
      _logger.apiResponse(AppConstants.authEndpoint, response.statusCode, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Store token and user data
        final token = data['data']['token'];
        final userData = data['data']['user'];
        
        await _authBox.put(AppConstants.tokenKey, token);
        await _authBox.put(AppConstants.userKey, userData);

        final user = User.fromJson(userData);
        _logger.authEvent('Login successful', userId: user.id);
        _logger.dataEvent('Store', 'User session', id: user.id);

        return {
          'success': true,
          'message': 'Login successful',
          'user': user,
        };
      } else {
        _logger.authEvent('Login failed: ${data['message']}', userId: username);
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e, stackTrace) {
      _logger.apiError(AppConstants.authEndpoint, e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Logout user
  Future<void> logout() async {
    final user = getCurrentUser();
    _logger.authEvent('Logout', userId: user?.id);
    
    await _authBox.delete(AppConstants.tokenKey);
    await _authBox.delete(AppConstants.userKey);
    
    _logger.dataEvent('Clear', 'User session');
  }

  // Get authorization headers
  Map<String, String> getAuthHeaders() {
    final token = getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Validate if current user has cashier role
  bool isCashierRole() {
    final user = getCurrentUser();
    return user?.role == AppConstants.cashierRole;
  }

  // Check if token is still valid (basic check)
  bool isTokenValid() {
    final token = getToken();
    if (token == null || token.isEmpty) return false;
    
    // You can add JWT token expiry check here
    // For now, just check if token exists
    return true;
  }

  // Refresh user data
  Future<bool> refreshUserData() async {
    try {
      if (!isLoggedIn()) return false;

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/me'),
        headers: getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          await _authBox.put(AppConstants.userKey, data['data']);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}