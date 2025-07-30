import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_theme.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.4,
      children: [
        _QuickActionCard(
          icon: Icons.sell,
          title: 'New Sale',
          subtitle: 'Sell vehicle to customer',
          color: AppTheme.successColor,
          onTap: () => context.go('/dashboard/sales'),
        ),
        _QuickActionCard(
          icon: Icons.shopping_cart,
          title: 'Purchase',
          subtitle: 'Buy from customer',
          color: Colors.orange,
          onTap: () => context.go('/dashboard/purchase'),
        ),
        _QuickActionCard(
          icon: Icons.people,
          title: 'Customers',
          subtitle: 'Manage customers',
          color: AppTheme.infoColor,
          onTap: () => context.go('/dashboard/customers'),
        ),
        _QuickActionCard(
          icon: Icons.directions_car,
          title: 'Inventory',
          subtitle: 'View available cars',
          color: AppTheme.warningColor,
          onTap: () => context.go('/dashboard/inventory'),
        ),
        _QuickActionCard(
          icon: Icons.receipt,
          title: 'Invoices',
          subtitle: 'View all invoices',
          color: Colors.purple,
          onTap: () => context.go('/dashboard/invoices'),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Icon(
                  icon,
                  size: 24.sp,
                  color: color,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}