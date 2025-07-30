import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/invoice.dart';
import '../models/api_models.dart';
import '../models/car.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class PurchaseService {
  final AuthService _authService = AuthService();
  final LoggerService _logger = logger;

  // Create a purchase transaction (buy vehicle from customer)
  Future<ApiResponse<Map<String, dynamic>>> createPurchase(CreatePurchaseRequest request) async {
    const operation = 'Create Purchase';
    _logger.userAction(operation, data: {
      'carId': request.carId,
      'amount': request.amount,
      'paymentMethod': request.paymentMethod,
    });

    try {
      final stopwatch = Stopwatch()..start();
      _logger.apiCall(AppConstants.buyEndpoint, method: 'POST', requestData: request.toJson());

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.buyEndpoint}'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode(request.toJson()),
      );

      stopwatch.stop();
      _logger.apiResponse(AppConstants.buyEndpoint, response.statusCode, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _logger.info('Purchase created successfully', tag: 'Purchase', data: {
          'invoiceNumber': data['data']['invoice']?['invoice_number'],
          'carId': request.carId,
        });

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'],
          data: data['data'], // Contains invoice, car, transaction data
        );
      } else {
        _logger.error('Purchase creation failed', tag: 'Purchase', error: data['message']);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? 'Failed to create purchase',
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError(AppConstants.buyEndpoint, e, stackTrace: stackTrace);
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get purchase invoices
  Future<ApiResponse<List<Invoice>>> getPurchaseInvoices({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    const operation = 'Get Purchase Invoices';
    _logger.userAction(operation, data: {'page': page, 'limit': limit});

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final uri = Uri.parse('${AppConstants.baseUrl}/buy-sell/purchases')
          .replace(queryParameters: queryParams);

      _logger.apiCall('/buy-sell/purchases', method: 'GET');

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      _logger.apiResponse('/buy-sell/purchases', response.statusCode);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final invoicesList = (data['data'] as List)
            .map((json) => Invoice.fromJson(json))
            .toList();

        _logger.info('Purchase invoices fetched', tag: 'Purchase', data: {'count': invoicesList.length});

        return ApiResponse<List<Invoice>>(
          success: true,
          message: data['message'],
          data: invoicesList,
          pagination: data['pagination'] != null 
              ? Pagination.fromJson(data['pagination'])
              : null,
        );
      } else {
        _logger.error('Failed to fetch purchase invoices', tag: 'Purchase', error: data['message']);
        return ApiResponse<List<Invoice>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch purchases',
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('/buy-sell/purchases', e, stackTrace: stackTrace);
      return ApiResponse<List<Invoice>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get available cars for purchase (cars that can be bought from customers)
  Future<ApiResponse<List<Car>>> getAvailableCarsForPurchase() async {
    const operation = 'Get Available Cars for Purchase';
    _logger.userAction(operation);

    try {
      _logger.apiCall('${AppConstants.carsEndpoint}/available', method: 'GET');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.carsEndpoint}/available'),
        headers: _authService.getAuthHeaders(),
      );

      _logger.apiResponse('${AppConstants.carsEndpoint}/available', response.statusCode);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final carsList = (data['data'] as List)
            .map((json) => Car.fromJson(json))
            .toList();

        _logger.info('Available cars for purchase fetched', tag: 'Purchase', data: {'count': carsList.length});

        return ApiResponse<List<Car>>(
          success: true,
          message: data['message'],
          data: carsList,
        );
      } else {
        _logger.error('Failed to fetch available cars', tag: 'Purchase', error: data['message']);
        return ApiResponse<List<Car>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch available cars',
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.carsEndpoint}/available', e, stackTrace: stackTrace);
      return ApiResponse<List<Car>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Calculate total amount (for purchases, usually no discount)
  double calculateTotalAmount(double amount, double discountAmount = 0) {
    return amount - discountAmount;
  }

  // Validate purchase request
  Map<String, String> validatePurchaseRequest(CreatePurchaseRequest request) {
    final errors = <String, String>{};

    _logger.businessLogic('Validate Purchase Request', data: request.toJson());

    if (request.carId.isEmpty) {
      errors['car'] = 'Car is required';
    }

    if (request.amount <= 0) {
      errors['amount'] = 'Amount must be greater than 0';
    }

    if (!AppConstants.paymentMethods.contains(request.paymentMethod)) {
      errors['payment_method'] = 'Invalid payment method';
    }

    if (request.createdBy.isEmpty) {
      errors['created_by'] = 'Creator is required';
    }

    if (errors.isNotEmpty) {
      _logger.warning('Purchase request validation failed', tag: 'Purchase', data: errors);
    } else {
      _logger.debug('Purchase request validation passed', tag: 'Purchase');
    }

    return errors;
  }

  // Get purchase summary for dashboard
  Future<ApiResponse<Map<String, dynamic>>> getPurchaseSummary({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    const operation = 'Get Purchase Summary';
    _logger.userAction(operation);

    try {
      final queryParams = <String, String>{};
      
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final uri = Uri.parse('${AppConstants.baseUrl}/buy-sell/purchases/summary')
          .replace(queryParameters: queryParams);

      _logger.apiCall('/buy-sell/purchases/summary', method: 'GET');

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      _logger.apiResponse('/buy-sell/purchases/summary', response.statusCode);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _logger.info('Purchase summary fetched', tag: 'Purchase', data: data['data']);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: data['message'],
          data: data['data'],
        );
      } else {
        _logger.error('Failed to fetch purchase summary', tag: 'Purchase', error: data['message']);
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch purchase summary',
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('/buy-sell/purchases/summary', e, stackTrace: stackTrace);
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get purchase invoice by number
  Future<ApiResponse<Invoice>> getPurchaseInvoiceByNumber(String invoiceNumber) async {
    const operation = 'Get Purchase Invoice by Number';
    _logger.userAction(operation, data: {'invoiceNumber': invoiceNumber});

    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.invoicesEndpoint}/number')
          .replace(queryParameters: {'number': invoiceNumber});

      _logger.apiCall('${AppConstants.invoicesEndpoint}/number', method: 'GET');

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      _logger.apiResponse('${AppConstants.invoicesEndpoint}/number', response.statusCode);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final invoice = Invoice.fromJson(data['data']);
        
        if (invoice.invoiceType == 'purchase') {
          _logger.info('Purchase invoice found', tag: 'Purchase', data: {'invoiceNumber': invoiceNumber});
          return ApiResponse<Invoice>(
            success: true,
            message: data['message'],
            data: invoice,
          );
        } else {
          _logger.warning('Invoice found but not a purchase invoice', tag: 'Purchase', 
                         data: {'invoiceNumber': invoiceNumber, 'type': invoice.invoiceType});
          return ApiResponse<Invoice>(
            success: false,
            message: 'Invoice is not a purchase invoice',
          );
        }
      } else {
        _logger.error('Purchase invoice not found', tag: 'Purchase', error: data['message']);
        return ApiResponse<Invoice>(
          success: false,
          message: data['message'] ?? 'Purchase invoice not found',
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.invoicesEndpoint}/number', e, stackTrace: stackTrace);
      return ApiResponse<Invoice>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}

// Purchase request model
class CreatePurchaseRequest {
  final String? customerId;  // Optional - customer selling the car
  final String carId;
  final double amount;
  final String paymentMethod;
  final String notes;
  final String createdBy;

  CreatePurchaseRequest({
    this.customerId,
    required this.carId,
    required this.amount,
    required this.paymentMethod,
    required this.notes,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      if (customerId != null && customerId!.isNotEmpty) 'customer_id': customerId,
      'car_id': carId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}