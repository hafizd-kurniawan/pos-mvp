import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/car.dart';
import '../services/photo_service.dart';
import '../utils/app_theme.dart';

class CarSelectionCard extends StatelessWidget {
  final Car car;
  final bool isSelected;
  final VoidCallback onTap;

  const CarSelectionCard({
    super.key,
    required this.car,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoService = PhotoService();
    
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car image
            Container(
              height: 120.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                child: car.primaryPhotoUrl != null
                    ? CachedNetworkImage(
                        imageUrl: photoService.getPhotoUrl(car.primaryPhotoUrl!),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            
            // Car details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car name
                    Text(
                      car.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    // License plate
                    Text(
                      car.licensePlate,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    // Car specs
                    Row(
                      children: [
                        _buildSpecChip(car.fuelType),
                        SizedBox(width: 4.w),
                        _buildSpecChip(car.transmission),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Price
                    if (car.sellingPrice != null) ...[
                      Text(
                        'Selling Price',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Rp ${car.sellingPrice!.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 8.h),
                    
                    // Status badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(car.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _getStatusColor(car.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        car.statusDisplayName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(car.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.directions_car,
          size: 40.sp,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildSpecChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return AppTheme.successColor;
      case 'in_repair':
        return AppTheme.warningColor;
      case 'sold':
        return Colors.grey;
      case 'reserved':
        return AppTheme.infoColor;
      default:
        return Colors.grey;
    }
  }
}