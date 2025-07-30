import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/customer.dart';
import '../models/api_models.dart';
import 'auth_service.dart';

class CustomerService {
  final AuthService _authService = AuthService();

  // Get all customers with pagination
  Future<ApiResponse<List<Customer>>> getCustomers({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.customersEndpoint}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final customersList = (data['data'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();

        return ApiResponse<List<Customer>>(
          success: true,
          message: data['message'],
          data: customersList,
          pagination: data['pagination'] != null 
              ? Pagination.fromJson(data['pagination'])
              : null,
        );
      } else {
        return ApiResponse<List<Customer>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch customers',
        );
      }
    } catch (e) {
      return ApiResponse<List<Customer>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Search customers by phone number
  Future<ApiResponse<List<Customer>>> searchCustomersByPhone(String phone) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/search')
          .replace(queryParameters: {'phone': phone});

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final customersList = (data['data'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();

        return ApiResponse<List<Customer>>(
          success: true,
          message: data['message'],
          data: customersList,
        );
      } else {
        return ApiResponse<List<Customer>>(
          success: false,
          message: data['message'] ?? 'No customers found',
        );
      }
    } catch (e) {
      return ApiResponse<List<Customer>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get customer by ID
  Future<ApiResponse<Customer>> getCustomerById(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/$customerId'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse<Customer>(
          success: true,
          message: data['message'],
          data: Customer.fromJson(data['data']),
        );
      } else {
        return ApiResponse<Customer>(
          success: false,
          message: data['message'] ?? 'Customer not found',
        );
      }
    } catch (e) {
      return ApiResponse<Customer>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Create new customer
  Future<ApiResponse<Customer>> createCustomer({
    required String name,
    required String email,
    required String phone,
    String? address,
    String? identityType,
    String? identityNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.customersEndpoint}'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'identity_type': identityType,
          'identity_number': identityNumber,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResponse<Customer>(
          success: true,
          message: data['message'],
          data: Customer.fromJson(data['data']),
        );
      } else {
        return ApiResponse<Customer>(
          success: false,
          message: data['message'] ?? 'Failed to create customer',
        );
      }
    } catch (e) {
      return ApiResponse<Customer>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Update customer
  Future<ApiResponse<Customer>> updateCustomer({
    required String customerId,
    required String name,
    required String email,
    required String phone,
    String? address,
    String? identityType,
    String? identityNumber,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/$customerId'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'identity_type': identityType,
          'identity_number': identityNumber,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse<Customer>(
          success: true,
          message: data['message'],
          data: Customer.fromJson(data['data']),
        );
      } else {
        return ApiResponse<Customer>(
          success: false,
          message: data['message'] ?? 'Failed to update customer',
        );
      }
    } catch (e) {
      return ApiResponse<Customer>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}