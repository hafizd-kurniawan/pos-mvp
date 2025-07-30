import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/invoice.dart';
import '../models/api_models.dart';
import 'auth_service.dart';

class SalesService {
  final AuthService _authService = AuthService();

  // Create a sale transaction
  Future<ApiResponse<Invoice>> createSale(CreateSaleRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.sellEndpoint}'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return ApiResponse<Invoice>(
          success: true,
          message: data['message'],
          data: Invoice.fromJson(data['data']['invoice']),
        );
      } else {
        return ApiResponse<Invoice>(
          success: false,
          message: data['message'] ?? 'Failed to create sale',
        );
      }
    } catch (e) {
      return ApiResponse<Invoice>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get sales invoices
  Future<ApiResponse<List<Invoice>>> getSalesInvoices({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final uri = Uri.parse('${AppConstants.baseUrl}/buy-sell/sales')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final invoicesList = (data['data'] as List)
            .map((json) => Invoice.fromJson(json))
            .toList();

        return ApiResponse<List<Invoice>>(
          success: true,
          message: data['message'],
          data: invoicesList,
          pagination: data['pagination'] != null 
              ? Pagination.fromJson(data['pagination'])
              : null,
        );
      } else {
        return ApiResponse<List<Invoice>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch sales',
        );
      }
    } catch (e) {
      return ApiResponse<List<Invoice>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Mark invoice as paid
  Future<ApiResponse<Invoice>> markInvoiceAsPaid({
    required String invoiceId,
    String? paymentProof,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.invoicesEndpoint}/$invoiceId/paid'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          if (paymentProof != null) 'payment_proof': paymentProof,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse<Invoice>(
          success: true,
          message: data['message'],
          data: Invoice.fromJson(data['data']),
        );
      } else {
        return ApiResponse<Invoice>(
          success: false,
          message: data['message'] ?? 'Failed to mark invoice as paid',
        );
      }
    } catch (e) {
      return ApiResponse<Invoice>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get invoice by number
  Future<ApiResponse<Invoice>> getInvoiceByNumber(String invoiceNumber) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.invoicesEndpoint}/number')
          .replace(queryParameters: {'number': invoiceNumber});

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse<Invoice>(
          success: true,
          message: data['message'],
          data: Invoice.fromJson(data['data']),
        );
      } else {
        return ApiResponse<Invoice>(
          success: false,
          message: data['message'] ?? 'Invoice not found',
        );
      }
    } catch (e) {
      return ApiResponse<Invoice>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Calculate total amount with discount
  double calculateTotalAmount(double amount, double discountAmount) {
    return amount - discountAmount;
  }

  // Calculate discount percentage
  double calculateDiscountPercentage(double amount, double discountAmount) {
    if (amount <= 0) return 0;
    return (discountAmount / amount) * 100;
  }

  // Validate sale request
  Map<String, String> validateSaleRequest(CreateSaleRequest request) {
    final errors = <String, String>{};

    if (request.customerId.isEmpty) {
      errors['customer'] = 'Customer is required';
    }

    if (request.carId.isEmpty) {
      errors['car'] = 'Car is required';
    }

    if (request.amount <= 0) {
      errors['amount'] = 'Amount must be greater than 0';
    }

    if (request.discountAmount < 0) {
      errors['discount'] = 'Discount cannot be negative';
    }

    if (request.discountAmount >= request.amount) {
      errors['discount'] = 'Discount cannot be greater than or equal to amount';
    }

    if (!AppConstants.paymentMethods.contains(request.paymentMethod)) {
      errors['payment_method'] = 'Invalid payment method';
    }

    return errors;
  }

  // Get sales summary for dashboard
  Future<ApiResponse<Map<String, dynamic>>> getSalesSummary({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final uri = Uri.parse('${AppConstants.baseUrl}/buy-sell/sales/summary')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'],
          data: data['data'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch sales summary',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}