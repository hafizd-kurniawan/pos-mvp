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
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.storefront_rounded,
                size: 20.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Car Showroom POS',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Cashier Dashboard',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // User info with modern design
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: Colors.white,
                  child: Text(
                    _currentUser?.name.substring(0, 1).toUpperCase() ?? 'C',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
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
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _currentUser?.roleDisplayName ?? 'Cashier',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Logout button with modern design
          Container(
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              onPressed: _handleLogout,
            ),
          ),
        ],
      ),
      
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern welcome section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF8FAFC),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.waving_hand_rounded,
                            size: 28.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 20.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${_currentUser?.name ?? 'Cashier'}! 👋',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Ready to serve customers and manage vehicle sales with our modern POS system',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16.sp,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Today: ${DateTime.now().toString().split(' ')[0]}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Stats section with modern title
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Today\'s Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20.h),
              
              const DashboardStatsCard(),
              
              SizedBox(height: 32.h),
              
              // Quick actions section
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      gradient: AppTheme.successGradient,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20.h),
              
              const QuickActionsGrid(),
              
              SizedBox(height: 32.h),
              
              // Recent transactions section
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      gradient: AppTheme.warningGradient,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20.h),
              
              const RecentTransactionsList(),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedBottomNavIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey.shade500,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded, size: 24.sp),
              activeIcon: Icon(Icons.dashboard_rounded, size: 26.sp),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sell_rounded, size: 24.sp),
              activeIcon: Icon(Icons.sell_rounded, size: 26.sp),
              label: 'Sales',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded, size: 24.sp),
              activeIcon: Icon(Icons.people_rounded, size: 26.sp),
              label: 'Customers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_rounded, size: 24.sp),
              activeIcon: Icon(Icons.directions_car_rounded, size: 26.sp),
              label: 'Cars',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_rounded, size: 24.sp),
              activeIcon: Icon(Icons.receipt_rounded, size: 26.sp),
              label: 'Invoices',
            ),
          ],
        ),
      ),
    );
  }
}