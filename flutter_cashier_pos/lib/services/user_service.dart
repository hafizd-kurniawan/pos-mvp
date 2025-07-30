import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../services/logger_service.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();
  final LoggerService _logger = logger;

  // Get users by role
  Future<Map<String, dynamic>> getUsersByRole(String role, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      _logger.info('Getting users by role', tag: 'User', data: {
        'role': role,
        'page': page,
        'limit': limit,
      });

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users?role=$role&page=$page&limit=$limit'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final usersData = data['data'] as List;
        final users = usersData.map((item) => User.fromJson(item)).toList();

        _logger.info('Users retrieved successfully', tag: 'User', data: {
          'role': role,
          'count': users.length,
        });

        return {
          'success': true,
          'message': 'Users retrieved successfully',
          'users': users,
          'pagination': data['pagination'],
        };
      } else {
        _logger.error('Failed to get users', tag: 'User', error: data['message']);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve users',
        };
      }
    } catch (e, stackTrace) {
      _logger.error('Get users error', tag: 'User', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all mechanics
  Future<List<User>> getMechanics() async {
    try {
      final response = await getUsersByRole('mechanic');
      if (response['success'] == true) {
        return response['users'] as List<User>;
      }
      return [];
    } catch (e) {
      _logger.error('Get mechanics error', tag: 'User', error: e);
      return [];
    }
  }

  // Get all users
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _logger.info('Getting all users', tag: 'User', data: {
        'page': page,
        'limit': limit,
      });

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users?page=$page&limit=$limit'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final usersData = data['data'] as List;
        final users = usersData.map((item) => User.fromJson(item)).toList();

        return {
          'success': true,
          'message': 'Users retrieved successfully',
          'users': users,
          'pagination': data['pagination'],
        };
      } else {
        _logger.error('Failed to get all users', tag: 'User', error: data['message']);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve users',
        };
      }
    } catch (e, stackTrace) {
      _logger.error('Get all users error', tag: 'User', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      _logger.info('Getting user by ID', tag: 'User', data: {'userId': userId});

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = User.fromJson(data['data']);

        return {
          'success': true,
          'message': 'User retrieved successfully',
          'user': user,
        };
      } else {
        _logger.error('Failed to get user', tag: 'User', error: data['message']);
        return {
          'success': false,
          'message': data['message'] ?? 'User not found',
        };
      }
    } catch (e, stackTrace) {
      _logger.error('Get user error', tag: 'User', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}