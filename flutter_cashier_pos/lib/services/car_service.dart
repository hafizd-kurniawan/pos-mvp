import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/car.dart';
import '../models/api_models.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class CarService {
  final AuthService _authService = AuthService();
  final LoggerService _logger = LoggerService();

  // Get available cars for sale
  Future<ApiResponse<List<Car>>> getAvailableCars({
    int page = 1,
    int limit = AppConstants.defaultPageSize,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'status': 'available', // Only available cars for cashier
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.carsEndpoint}')
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
        final carsList = (data['data'] as List? ?? [])
            .map((json) => Car.fromJson(json))
            .toList();

        return ApiResponse<List<Car>>(
          success: true,
          message: data['message'] ?? 'Cars retrieved successfully',
          data: carsList,
          pagination: data['pagination'] != null 
              ? Pagination.fromJson(data['pagination'])
              : null,
        );
      } else {
        final errorMessage = data['message'] ?? 'Failed to fetch cars';
        _logger.apiError(uri.toString(), error: errorMessage, statusCode: response.statusCode, response: data);
        
        return ApiResponse<List<Car>>(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.baseUrl}${AppConstants.carsEndpoint}', 
                      error: e, stackTrace: stackTrace);
      _logger.networkError('${AppConstants.baseUrl}${AppConstants.carsEndpoint}', 'Get cars failed: $e');
      
      return ApiResponse<List<Car>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get car by ID with photos
  Future<ApiResponse<Car>> getCarById(String carId) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.carsEndpoint}/$carId');
      
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
        return ApiResponse<Car>(
          success: true,
          message: data['message'] ?? 'Car found',
          data: Car.fromJson(data['data']),
        );
      } else {
        final errorMessage = data['message'] ?? 'Car not found';
        _logger.apiError(uri.toString(), error: errorMessage, statusCode: response.statusCode, response: data);
        
        return ApiResponse<Car>(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.baseUrl}${AppConstants.carsEndpoint}/$carId', 
                      error: e, stackTrace: stackTrace);
      _logger.networkError('${AppConstants.baseUrl}${AppConstants.carsEndpoint}/$carId', 'Get car failed: $e');
      
      return ApiResponse<Car>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Search cars by various criteria
  Future<ApiResponse<List<Car>>> searchCars({
    String? brand,
    String? model,
    int? yearFrom,
    int? yearTo,
    double? priceFrom,
    double? priceTo,
    String? fuelType,
    String? transmission,
    int page = 1,
    int limit = AppConstants.defaultPageSize,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'status': 'available', // Only available cars
      };

      if (brand != null && brand.isNotEmpty) queryParams['brand'] = brand;
      if (model != null && model.isNotEmpty) queryParams['model'] = model;
      if (yearFrom != null) queryParams['year_from'] = yearFrom.toString();
      if (yearTo != null) queryParams['year_to'] = yearTo.toString();
      if (priceFrom != null) queryParams['price_from'] = priceFrom.toString();
      if (priceTo != null) queryParams['price_to'] = priceTo.toString();
      if (fuelType != null && fuelType.isNotEmpty) queryParams['fuel_type'] = fuelType;
      if (transmission != null && transmission.isNotEmpty) queryParams['transmission'] = transmission;

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.carsEndpoint}/search')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final carsList = (data['data'] as List)
            .map((json) => Car.fromJson(json))
            .toList();

        return ApiResponse<List<Car>>(
          success: true,
          message: data['message'],
          data: carsList,
          pagination: data['pagination'] != null 
              ? Pagination.fromJson(data['pagination'])
              : null,
        );
      } else {
        return ApiResponse<List<Car>>(
          success: false,
          message: data['message'] ?? 'No cars found',
        );
      }
    } catch (e) {
      return ApiResponse<List<Car>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get car brands for filtering
  Future<ApiResponse<List<String>>> getCarBrands() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.carsEndpoint}/brands'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final brandsList = (data['data'] as List)
            .map((brand) => brand.toString())
            .toList();

        return ApiResponse<List<String>>(
          success: true,
          message: data['message'],
          data: brandsList,
        );
      } else {
        return ApiResponse<List<String>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch brands',
        );
      }
    } catch (e) {
      return ApiResponse<List<String>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get car models by brand
  Future<ApiResponse<List<String>>> getCarModelsByBrand(String brand) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.carsEndpoint}/models')
          .replace(queryParameters: {'brand': brand});

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final modelsList = (data['data'] as List)
            .map((model) => model.toString())
            .toList();

        return ApiResponse<List<String>>(
          success: true,
          message: data['message'],
          data: modelsList,
        );
      } else {
        return ApiResponse<List<String>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch models',
        );
      }
    } catch (e) {
      return ApiResponse<List<String>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}