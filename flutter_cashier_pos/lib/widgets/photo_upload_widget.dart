import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';
import '../services/image_upload_service.dart';
import '../services/logger_service.dart';
import '../utils/app_theme.dart';

class PhotoUploadWidget extends StatefulWidget {
  final Function(List<XFile>) onPhotosSelected;
  final Function(List<XFile>, List<String>)? onPhotosSelectedWithTypes;
  final bool allowMultiple;
  final List<String>? allowedPhotoTypes;
  final String? title;
  final String? subtitle;
  final bool enablePhotoTypeSelection;

  const PhotoUploadWidget({
    Key? key,
    required this.onPhotosSelected,
    this.onPhotosSelectedWithTypes,
    this.allowMultiple = true,
    this.allowedPhotoTypes,
    this.title,
    this.subtitle,
    this.enablePhotoTypeSelection = false,
  }) : super(key: key);

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final ImageUploadService _imageService = ImageUploadService();
  final LoggerService _logger = LoggerService();
  
  List<XFile> _selectedImages = [];
  List<String> _selectedPhotoTypes = [];
  bool _isProcessing = false;

  // Photo type options
  static const Map<String, String> photoTypeOptions = {
    'front': 'Front View',
    'back': 'Back View',
    'left': 'Left Side',
    'right': 'Right Side',
    'interior': 'Interior',
    'engine': 'Engine Bay',
    'dashboard': 'Dashboard',
    'damage': 'Damage',
    'before': 'Before Repair',
    'after': 'After Repair',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.photo_camera, color: AppTheme.primaryColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  widget.title ?? 'Upload Photos',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (widget.subtitle != null) ...[
              SizedBox(height: 4.h),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: 16.h),

            // Upload buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromCamera,
                    icon: Icon(Icons.camera_alt, size: 20.sp),
                    label: Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: Icon(Icons.photo_library, size: 20.sp),
                    label: Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Selected images preview
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                'Selected Photos (${_selectedImages.length})',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.h),
              _buildImagePreview(),
            ],

            // Processing indicator
            if (_isProcessing) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Processing images...',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 80.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          final image = _selectedImages[index];
          return Container(
            width: 80.w,
            margin: EdgeInsets.only(right: 8.w),
            child: Stack(
              children: [
                // Image preview with platform-specific handling
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: kIsWeb
                      ? FutureBuilder<Uint8List>(
                          future: image.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                width: 80.w,
                                height: 80.h,
                                fit: BoxFit.cover,
                              );
                            }
                            return Container(
                              width: 80.w,
                              height: 80.h,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        )
                      : Image.file(
                          File(image.path),
                          width: 80.w,
                          height: 80.h,
                          fit: BoxFit.cover,
                        ),
                ),
                
                // Remove button
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    setState(() => _isProcessing = true);
    
    try {
      final image = await _imageService.pickImageFromCamera();
      
      if (image != null) {
        if (await _imageService.validateImageFile(image)) {
          setState(() {
            if (widget.allowMultiple) {
              _selectedImages.add(image);
              _selectedPhotoTypes.add('front'); // Default to front
            } else {
              _selectedImages = [image];
              _selectedPhotoTypes = ['front'];
            }
          });
          
          widget.onPhotosSelected(_selectedImages);
          if (widget.onPhotosSelectedWithTypes != null) {
            widget.onPhotosSelectedWithTypes!(_selectedImages, _selectedPhotoTypes);
          }
          
          _logger.userAction('Photo selected from camera', data: {
            'fileName': image.name,
            'totalPhotos': _selectedImages.length,
          });
        } else {
          _showErrorSnackBar('Invalid image file. Please check file size and format.');
        }
      }
    } catch (e) {
      _logger.error('Camera photo selection failed', tag: 'PhotoUpload', error: e);
      _showErrorSnackBar('Failed to capture photo: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isProcessing = true);
    
    try {
      if (widget.allowMultiple) {
        final images = await _imageService.pickMultipleImages();
        
        if (images != null && images.isNotEmpty) {
          final validImages = <XFile>[];
          
          for (final image in images) {
            if (await _imageService.validateImageFile(image)) {
              validImages.add(image);
            }
          }
          
          if (validImages.isNotEmpty) {
            setState(() {
              _selectedImages.addAll(validImages);
              // Add default photo types for new images
              for (int i = 0; i < validImages.length; i++) {
                _selectedPhotoTypes.add('front');
              }
            });
            widget.onPhotosSelected(_selectedImages);
            if (widget.onPhotosSelectedWithTypes != null) {
              widget.onPhotosSelectedWithTypes!(_selectedImages, _selectedPhotoTypes);
            }
            
            _logger.userAction('Multiple photos selected from gallery', data: {
              'count': validImages.length,
              'totalPhotos': _selectedImages.length,
            });
          }
          
          if (validImages.length < images.length) {
            _showErrorSnackBar('Some images were skipped due to invalid format or size.');
          }
        }
      } else {
        final image = await _imageService.pickImageFromGallery();
        
        if (image != null) {
          if (await _imageService.validateImageFile(image)) {
            setState(() {
              _selectedImages = [image];
              _selectedPhotoTypes = ['front'];
            });
            widget.onPhotosSelected(_selectedImages);
            if (widget.onPhotosSelectedWithTypes != null) {
              widget.onPhotosSelectedWithTypes!(_selectedImages, _selectedPhotoTypes);
            }
            
            _logger.userAction('Photo selected from gallery', data: {
              'fileName': image.name,
            });
          } else {
            _showErrorSnackBar('Invalid image file. Please check file size and format.');
          }
        }
      }
    } catch (e) {
      _logger.error('Gallery photo selection failed', tag: 'PhotoUpload', error: e);
      _showErrorSnackBar('Failed to select photos: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _selectedPhotoTypes.length) {
        _selectedPhotoTypes.removeAt(index);
      }
    });
    widget.onPhotosSelected(_selectedImages);
    if (widget.onPhotosSelectedWithTypes != null) {
      widget.onPhotosSelectedWithTypes!(_selectedImages, _selectedPhotoTypes);
    }
    
    _logger.userAction('Photo removed', data: {
      'index': index,
      'totalPhotos': _selectedImages.length,
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}