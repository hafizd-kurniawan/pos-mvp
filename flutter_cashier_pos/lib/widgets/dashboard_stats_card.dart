import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_theme.dart';

class DashboardStatsCard extends StatelessWidget {
  const DashboardStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModernStatCard(
            title: 'Today Sales',
            value: '0',
            subtitle: 'transactions',
            icon: Icons.trending_up_rounded,
            gradient: AppTheme.successGradient,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _ModernStatCard(
            title: 'Available Cars',
            value: '0',
            subtitle: 'vehicles',
            icon: Icons.directions_car_rounded,
            gradient: AppTheme.primaryGradient,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _ModernStatCard(
            title: 'Pending',
            value: '0',
            subtitle: 'invoices',
            icon: Icons.pending_actions_rounded,
            gradient: AppTheme.warningGradient,
          ),
        ),
      ],
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: Colors.white,
        boxShadow: AppTheme.modernCardShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 24.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade900,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}