import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/customer.dart';
import '../models/api_models.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class CustomerService {
  final AuthService _authService = AuthService();
  final LoggerService _logger = LoggerService();

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

      _logger.apiCall(uri.toString(), method: 'GET');
      final stopwatch = Stopwatch()..start();

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      stopwatch.stop();
      _logger.apiResponse(uri.toString(), response.statusCode, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final customersList = (data['data'] as List? ?? [])
            .map((json) => Customer.fromJson(json))
            .toList();

        return ApiResponse<List<Customer>>(
          success: true,
          message: data['message'] ?? 'Customers retrieved successfully',
          data: customersList,
          pagination: data['pagination'] != null 
              ? Pagination.fromJson(data['pagination'])
              : null,
        );
      } else {
        final errorMessage = data['message'] ?? 'Failed to fetch customers';
        _logger.apiError(uri.toString(), error: errorMessage, statusCode: response.statusCode, response: data);
        
        return ApiResponse<List<Customer>>(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}', 
                      error: e, stackTrace: stackTrace);
      _logger.networkError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}', 'Network error: $e');
      
      return ApiResponse<List<Customer>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Search customers by phone number
  Future<ApiResponse<List<Customer>>> searchCustomersByPhone(String phone) async {
    try {
      // Backend expects 'q' parameter for search, not 'phone'
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/search')
          .replace(queryParameters: {'q': phone});

      _logger.apiCall(uri.toString(), method: 'GET');
      final stopwatch = Stopwatch()..start();

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      stopwatch.stop();
      _logger.apiResponse(uri.toString(), response.statusCode, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final customersList = (data['data'] as List? ?? [])
            .map((json) => Customer.fromJson(json))
            .toList();

        return ApiResponse<List<Customer>>(
          success: true,
          message: data['message'] ?? 'Customers found',
          data: customersList,
        );
      } else {
        final errorMessage = data['message'] ?? 'No customers found';
        _logger.apiError(uri.toString(), error: errorMessage, statusCode: response.statusCode, response: data);
        
        return ApiResponse<List<Customer>>(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/search', 
                      error: e, stackTrace: stackTrace);
      _logger.networkError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/search', 'Customer search failed: $e');
      
      return ApiResponse<List<Customer>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get customer by ID
  Future<ApiResponse<Customer>> getCustomerById(String customerId) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/$customerId');
      
      _logger.apiCall(uri.toString(), method: 'GET');
      final stopwatch = Stopwatch()..start();

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      stopwatch.stop();
      _logger.apiResponse(uri.toString(), response.statusCode, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse<Customer>(
          success: true,
          message: data['message'] ?? 'Customer found',
          data: Customer.fromJson(data['data']),
        );
      } else {
        final errorMessage = data['message'] ?? 'Customer not found';
        _logger.apiError(uri.toString(), error: errorMessage, statusCode: response.statusCode, response: data);
        
        return ApiResponse<Customer>(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/$customerId', 
                      error: e, stackTrace: stackTrace);
      _logger.networkError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/$customerId', 'Get customer failed: $e');
      
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
      // Split name into first_name and last_name for backend
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      // Backend requires last_name field even if empty
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'N/A';

      final requestBody = {
        'first_name': firstName,
        'last_name': lastName, // Always provide this as backend requires it
        'email': email,
        'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (identityType != null && identityType.isNotEmpty) 'identity_type': identityType,
        if (identityNumber != null && identityNumber.isNotEmpty) 'identity_number': identityNumber,
      };

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.customersEndpoint}');
      
      _logger.apiCall(uri.toString(), method: 'POST', requestData: requestBody);
      final stopwatch = Stopwatch()..start();

      final response = await http.post(
        uri,
        headers: _authService.getAuthHeaders(),
        body: jsonEncode(requestBody),
      );

      stopwatch.stop();
      _logger.apiResponse(uri.toString(), response.statusCode, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _logger.info('Customer created successfully', tag: 'CustomerService');
        
        return ApiResponse<Customer>(
          success: true,
          message: data['message'] ?? 'Customer created successfully',
          data: Customer.fromJson(data['data']),
        );
      } else {
        final errorMessage = data['message'] ?? 'Failed to create customer';
        _logger.apiError(uri.toString(), error: errorMessage, statusCode: response.statusCode, response: data);
        
        return ApiResponse<Customer>(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}', 
                      error: e, stackTrace: stackTrace);
      _logger.networkError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}', 'Customer creation failed: $e');
      
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
      // Split name into first_name and last_name for backend
      final nameParts = name.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      // Backend requires last_name field even if empty
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'N/A';

      final requestBody = {
        'first_name': firstName,
        'last_name': lastName, // Always provide this as backend requires it
        'email': email,
        'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (identityType != null && identityType.isNotEmpty) 'identity_type': identityType,
        if (identityNumber != null && identityNumber.isNotEmpty) 'identity_number': identityNumber,
      };

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/$customerId');
      
      _logger.apiCall(uri.toString(), method: 'PUT', requestData: requestBody);
      final stopwatch = Stopwatch()..start();

      final response = await http.put(
        uri,
        headers: _authService.getAuthHeaders(),
        body: jsonEncode(requestBody),
      );

      stopwatch.stop();
      _logger.apiResponse(uri.toString(), response.statusCode, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _logger.info('Customer updated successfully', tag: 'CustomerService');
        
        return ApiResponse<Customer>(
          success: true,
          message: data['message'] ?? 'Customer updated successfully',
          data: Customer.fromJson(data['data']),
        );
      } else {
        final errorMessage = data['message'] ?? 'Failed to update customer';
        _logger.apiError(uri.toString(), error: errorMessage, statusCode: response.statusCode, response: data);
        
        return ApiResponse<Customer>(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/$customerId', 
                      error: e, stackTrace: stackTrace);
      _logger.networkError('${AppConstants.baseUrl}${AppConstants.customersEndpoint}/$customerId', 'Customer update failed: $e');
      
      return ApiResponse<Customer>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}