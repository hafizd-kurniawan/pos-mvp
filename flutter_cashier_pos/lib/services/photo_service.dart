import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/photo.dart';
import '../models/api_models.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class PhotoService {
  final AuthService _authService = AuthService();
  final LoggerService _logger = LoggerService();

  // Get all photos for an entity (car, work order, etc.)
  Future<ApiResponse<List<Photo>>> getEntityPhotos({
    required String entityType,
    required String entityId,
    String? photoType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (photoType != null && photoType.isNotEmpty) {
        queryParams['type'] = photoType;
      }

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.photosEndpoint}/entity/$entityType/$entityId')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final photosList = (data['data'] as List)
            .map((json) => Photo.fromJson(json))
            .toList();

        return ApiResponse<List<Photo>>(
          success: true,
          message: data['message'],
          data: photosList,
        );
      } else {
        return ApiResponse<List<Photo>>(
          success: false,
          message: data['message'] ?? 'Failed to fetch photos',
        );
      }
    } catch (e) {
      return ApiResponse<List<Photo>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get primary photo for an entity
  Future<ApiResponse<Photo?>> getPrimaryPhoto({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.photosEndpoint}/primary/$entityType/$entityId');
      
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
        return ApiResponse<Photo?>(
          success: true,
          message: data['message'] ?? 'Primary photo retrieved successfully',
          data: data['data'] != null ? Photo.fromJson(data['data']) : null,
        );
      } else if (response.statusCode == 404) {
        // No primary photo found - this is normal
        return ApiResponse<Photo?>(
          success: true,
          message: 'No primary photo found',
          data: null,
        );
      } else {
        final errorMessage = data['message'] ?? 'Failed to get primary photo';
        _logger.apiError(uri.toString(), error: errorMessage, statusCode: response.statusCode, response: data);
        
        return ApiResponse<Photo?>(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.baseUrl}${AppConstants.photosEndpoint}/primary/$entityType/$entityId', 
                      error: e, stackTrace: stackTrace);
      _logger.networkError('${AppConstants.baseUrl}${AppConstants.photosEndpoint}/primary/$entityType/$entityId', 'Get primary photo failed: $e');
      
      return ApiResponse<Photo?>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Set primary photo for an entity
  Future<ApiResponse<bool>> setPrimaryPhoto({
    required String entityType,
    required String entityId,
    required String photoId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.photosEndpoint}/primary/$entityType/$entityId/$photoId'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse<bool>(
          success: true,
          message: data['message'],
          data: true,
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: data['message'] ?? 'Failed to set primary photo',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get photos by type
  Future<ApiResponse<List<Photo>>> getPhotosByType({
    required String entityType,
    required String entityId,
    required String photoType,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.photosEndpoint}/type/$entityType/$entityId/$photoType'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final photosList = (data['data'] as List)
            .map((json) => Photo.fromJson(json))
            .toList();

        return ApiResponse<List<Photo>>(
          success: true,
          message: data['message'],
          data: photosList,
        );
      } else {
        return ApiResponse<List<Photo>>(
          success: false,
          message: data['message'] ?? 'No photos found',
        );
      }
    } catch (e) {
      return ApiResponse<List<Photo>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Get car photo gallery organized by type
  Future<ApiResponse<Map<String, List<Photo>>>> getCarPhotoGallery(String carId) async {
    try {
      final response = await getEntityPhotos(
        entityType: 'car',
        entityId: carId,
      );

      if (response.isSuccess && response.data != null) {
        final photos = response.data!;
        final gallery = <String, List<Photo>>{};

        // Group photos by type
        for (final photo in photos) {
          final type = photo.photoType ?? 'general';
          if (gallery[type] == null) {
            gallery[type] = [];
          }
          gallery[type]!.add(photo);
        }

        return ApiResponse<Map<String, List<Photo>>>(
          success: true,
          message: response.message,
          data: gallery,
        );
      } else {
        return ApiResponse<Map<String, List<Photo>>>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, List<Photo>>>(
        success: false,
        message: 'Error organizing photos: $e',
      );
    }
  }

  // Get formatted photo URL
  String getPhotoUrl(String filePath) {
    if (filePath.startsWith('http')) {
      return filePath;
    }
    // Remove leading slash if present and add base URL
    final cleanPath = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '${AppConstants.baseUrl.replaceAll('/api', '')}/$cleanPath';
  }

  // Get photo thumbnail URL (if backend supports thumbnails)
  String getPhotoThumbnailUrl(String filePath) {
    final url = getPhotoUrl(filePath);
    // If backend supports thumbnails, you can modify the URL here
    return url.replaceAll('/uploads/', '/uploads/thumbnails/');
  }

  // Check if photo type is for damage documentation
  bool isDamagePhoto(String? photoType) {
    return photoType == 'damage';
  }

  // Check if photo type is for repair documentation
  bool isRepairPhoto(String? photoType) {
    return photoType == 'before' || photoType == 'after';
  }

  // Get available photo types for cars
  List<String> getCarPhotoTypes() {
    return [
      'front',
      'back', 
      'left',
      'right',
      'interior',
      'engine',
      'dashboard',
      'damage',
      'before',
      'after',
    ];
  }

  // Get photo type display order for gallery
  List<String> getPhotoTypeDisplayOrder() {
    return [
      'front',
      'back',
      'left', 
      'right',
      'interior',
      'dashboard',
      'engine',
      'damage',
      'before',
      'after',
    ];
  }
}