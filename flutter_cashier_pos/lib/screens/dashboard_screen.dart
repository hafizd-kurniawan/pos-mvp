import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/recent_transactions_list.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  int _selectedBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _currentUser = _authService.getCurrentUser();
    setState(() {});
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        // Dashboard - already here
        break;
      case 1:
        context.go('/dashboard/sales');
        break;
      case 2:
        context.go('/dashboard/customers');
        break;
      case 3:
        context.go('/dashboard/inventory');
        break;
      case 4:
        context.go('/dashboard/invoices');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.point_of_sale,
              size: 24.sp,
              color: Colors.white,
            ),
            SizedBox(width: 8.w),
            Text(
              'Car Showroom POS',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // User info
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    _currentUser?.name.substring(0, 1).toUpperCase() ?? 'C',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.name ?? 'Cashier',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _currentUser?.roleDisplayName ?? 'Cashier',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Logout button
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.white,
              size: 24.sp,
            ),
            onPressed: _handleLogout,
          ),
        ],
      ),
      
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_currentUser?.name ?? 'Cashier'}!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Ready to serve customers and manage sales',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Today: ${DateTime.now().toString().split(' ')[0]}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Stats cards
              const DashboardStatsCard(),
              
              SizedBox(height: 24.h),
              
              // Quick actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              const QuickActionsGrid(),
              
              SizedBox(height: 24.h),
              
              // Recent transactions
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              const RecentTransactionsList(),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomNavIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, size: 24.sp),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell, size: 24.sp),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people, size: 24.sp),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car, size: 24.sp),
            label: 'Cars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt, size: 24.sp),
            label: 'Invoices',
          ),
        ],
      ),
    );
  }
}