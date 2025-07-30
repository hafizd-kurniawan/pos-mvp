import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../models/api_models.dart';
import '../models/photo.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class ImageUploadService {
  final AuthService _authService = AuthService();
  final LoggerService _logger = LoggerService();
  final ImagePicker _picker = ImagePicker();

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      _logger.userAction('Pick image from camera');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        _logger.info('Image picked from camera', tag: 'ImageUpload', data: {
          'path': image.path,
          'name': image.name,
        });
      }
      
      return image;
    } catch (e, stackTrace) {
      _logger.error('Failed to pick image from camera', tag: 'ImageUpload', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      _logger.userAction('Pick image from gallery');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        _logger.info('Image picked from gallery', tag: 'ImageUpload', data: {
          'path': image.path,
          'name': image.name,
        });
      }
      
      return image;
    } catch (e, stackTrace) {
      _logger.error('Failed to pick image from gallery', tag: 'ImageUpload', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Pick multiple images from gallery
  Future<List<XFile>?> pickMultipleImages() async {
    try {
      _logger.userAction('Pick multiple images from gallery');
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      _logger.info('Multiple images picked from gallery', tag: 'ImageUpload', data: {
        'count': images.length,
        'names': images.map((img) => img.name).toList(),
      });
      
      return images;
    } catch (e, stackTrace) {
      _logger.error('Failed to pick multiple images', tag: 'ImageUpload', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Upload single image to server
  Future<ApiResponse<Photo>> uploadImage({
    required XFile imageFile,
    required String entityType,
    required String entityId,
    String? photoType,
    String? description,
    bool setPrimary = false,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.photosEndpoint}/upload');
      
      _logger.apiCall(uri.toString(), method: 'POST');
      final stopwatch = Stopwatch()..start();

      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(_authService.getAuthHeaders());
      
      // Add form fields
      request.fields['entity_type'] = entityType;
      request.fields['entity_id'] = entityId;
      if (photoType != null) request.fields['photo_type'] = photoType;
      if (description != null) request.fields['description'] = description;
      if (setPrimary) request.fields['set_primary'] = 'true';

      // Add file
      final file = await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        filename: imageFile.name,
      );
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      stopwatch.stop();
      _logger.apiResponse(uri.toString(), response.statusCode, duration: stopwatch.elapsed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        _logger.info('Image uploaded successfully', tag: 'ImageUpload', data: {
          'photoId': data['data']?['id'],
          'entityType': entityType,
          'entityId': entityId,
          'photoType': photoType,
        });

        return ApiResponse<Photo>(
          success: true,
          message: data['message'] ?? 'Image uploaded successfully',
          data: Photo.fromJson(data['data']),
        );
      } else {
        final errorMessage = data['message'] ?? 'Failed to upload image';
        _logger.apiError(uri.toString(), error: errorMessage, statusCode: response.statusCode, response: data);
        
        return ApiResponse<Photo>(
          success: false,
          message: errorMessage,
        );
      }
    } catch (e, stackTrace) {
      _logger.apiError('${AppConstants.baseUrl}${AppConstants.photosEndpoint}/upload', 
                      error: e, stackTrace: stackTrace);
      _logger.networkError('${AppConstants.baseUrl}${AppConstants.photosEndpoint}/upload', 'Image upload failed: $e');
      
      return ApiResponse<Photo>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Upload multiple images
  Future<ApiResponse<List<Photo>>> uploadMultipleImages({
    required List<XFile> imageFiles,
    required String entityType,
    required String entityId,
    List<String>? photoTypes,
    String? description,
  }) async {
    try {
      final List<Photo> uploadedPhotos = [];
      final List<String> errors = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        final photoType = (photoTypes != null && i < photoTypes.length) ? photoTypes[i] : null;
        
        final response = await uploadImage(
          imageFile: imageFile,
          entityType: entityType,
          entityId: entityId,
          photoType: photoType,
          description: description,
          setPrimary: i == 0, // Set first image as primary
        );

        if (response.isSuccess && response.data != null) {
          uploadedPhotos.add(response.data!);
        } else {
          errors.add('${imageFile.name}: ${response.message}');
        }
      }

      if (uploadedPhotos.isNotEmpty) {
        return ApiResponse<List<Photo>>(
          success: true,
          message: errors.isEmpty 
              ? 'All images uploaded successfully'
              : 'Some images uploaded with errors: ${errors.join(', ')}',
          data: uploadedPhotos,
        );
      } else {
        return ApiResponse<List<Photo>>(
          success: false,
          message: 'Failed to upload images: ${errors.join(', ')}',
        );
      }
    } catch (e, stackTrace) {
      _logger.error('Multiple image upload failed', tag: 'ImageUpload', error: e, stackTrace: stackTrace);
      
      return ApiResponse<List<Photo>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Validate image file
  bool validateImageFile(XFile imageFile) {
    // Check file size (max 10MB)
    final file = File(imageFile.path);
    final fileSize = file.lengthSync();
    
    if (fileSize > AppConstants.maxFileSize) {
      _logger.warning('Image file too large', tag: 'ImageUpload', data: {
        'fileSize': fileSize,
        'maxSize': AppConstants.maxFileSize,
        'fileName': imageFile.name,
      });
      return false;
    }

    // Check file extension
    final extension = imageFile.path.split('.').last.toLowerCase();
    if (!AppConstants.allowedImageTypes.contains(extension)) {
      _logger.warning('Invalid image type', tag: 'ImageUpload', data: {
        'extension': extension,
        'allowedTypes': AppConstants.allowedImageTypes,
        'fileName': imageFile.name,
      });
      return false;
    }

    return true;
  }

  // Get file size in human readable format
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog() async {
    // This would typically be implemented in the UI layer
    // Return null for now, implement in calling widget
    return null;
  }
}