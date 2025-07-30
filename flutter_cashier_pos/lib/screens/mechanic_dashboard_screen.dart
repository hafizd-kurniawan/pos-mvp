import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../services/auth_service.dart';
import '../services/work_order_service.dart';
import '../models/work_order.dart';
import '../widgets/loading_overlay.dart';
import '../utils/app_theme.dart';

class MechanicDashboardScreen extends ConsumerStatefulWidget {
  const MechanicDashboardScreen({super.key});

  @override
  ConsumerState<MechanicDashboardScreen> createState() => _MechanicDashboardScreenState();
}

class _MechanicDashboardScreenState extends ConsumerState<MechanicDashboardScreen> {
  final AuthService _authService = AuthService();
  final WorkOrderService _workOrderService = WorkOrderService();
  
  List<WorkOrder> _myWorkOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyWorkOrders();
  }

  Future<void> _loadMyWorkOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _workOrderService.getMyWorkOrders();
      
      if (result['success'] == true) {
        setState(() {
          _myWorkOrders = result['workOrders'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading work orders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProgress(WorkOrder workOrder, int newProgress) async {
    try {
      final result = await _workOrderService.updateProgress(workOrder.id, newProgress);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress updated successfully')),
        );
        _loadMyWorkOrders(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update progress')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    final pendingOrders = _myWorkOrders.where((wo) => wo.isPending).length;
    final inProgressOrders = _myWorkOrders.where((wo) => wo.isInProgress).length;
    final completedToday = _myWorkOrders.where((wo) => 
        wo.isCompleted && 
        wo.completedDate != null && 
        wo.completedDate!.day == DateTime.now().day
    ).length;

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
                Icons.build_rounded,
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
                  'Workshop Dashboard',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Mechanic Portal',
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
                    user?.name.substring(0, 1).toUpperCase() ?? 'M',
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
                      user?.name ?? 'Mechanic',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Mechanic',
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
          
          // Refresh button
          Container(
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              onPressed: _loadMyWorkOrders,
            ),
          ),
          
          // Logout button
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
              onPressed: () async {
                await _authService.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: RefreshIndicator(
          onRefresh: _loadMyWorkOrders,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern welcome card
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
                  child: Row(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.engineering_rounded,
                          size: 40.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 24.w),
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
                              '${user?.name ?? 'Mechanic'}! 🔧',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Professional Automotive Workshop',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Modern statistics section
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
                      'Workshop Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20.h),

                ResponsiveRowColumn(
                  layout: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                      ? ResponsiveRowColumnType.ROW
                      : ResponsiveRowColumnType.COLUMN,
                  rowMainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: _buildModernStatCard(
                        'Pending Orders',
                        pendingOrders.toString(),
                        Icons.pending_actions_rounded,
                        AppTheme.warningGradient,
                      ),
                    ),
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: _buildModernStatCard(
                        'In Progress',
                        inProgressOrders.toString(),
                        Icons.build_circle_rounded,
                        AppTheme.primaryGradient,
                      ),
                    ),
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: _buildModernStatCard(
                        'Completed Today',
                        completedToday.toString(),
                        Icons.check_circle_rounded,
                        AppTheme.successGradient,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Work Orders Section with modern design
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
                      'My Work Orders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: AppTheme.primaryColor,
                          size: 20.sp,
                        ),
                        onPressed: _loadMyWorkOrders,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20.h),

                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: AppTheme.errorGradient.scale(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppTheme.errorColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.errorColor,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_myWorkOrders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(48.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: AppTheme.modernCardShadow,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80.w,
                          height: 80.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Icon(
                            Icons.work_off_rounded,
                            size: 40.sp,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'No work orders assigned',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'You currently have no work orders assigned to you.\nCheck back later for new assignments.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _myWorkOrders.map((workOrder) {
                      return _buildModernWorkOrderCard(workOrder);
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, LinearGradient gradient) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
              title.toLowerCase(),
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

  Widget _buildModernWorkOrderCard(WorkOrder workOrder) {
    LinearGradient statusGradient;
    switch (workOrder.status) {
      case 'pending':
        statusGradient = AppTheme.warningGradient;
        break;
      case 'in_progress':
        statusGradient = AppTheme.primaryGradient;
        break;
      case 'completed':
        statusGradient = AppTheme.successGradient;
        break;
      case 'cancelled':
        statusGradient = AppTheme.errorGradient;
        break;
      default:
        statusGradient = const LinearGradient(colors: [Colors.grey, Colors.grey]);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: AppTheme.modernCardShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workOrder.workOrderNumber,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        workOrder.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: statusGradient.scale(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: statusGradient.colors.first.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    workOrder.statusDisplayName,
                    style: TextStyle(
                      color: statusGradient.colors.first,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Modern progress bar
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${workOrder.progress}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: statusGradient.colors.first,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: workOrder.progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: statusGradient,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress buttons (for in-progress orders)
            if (workOrder.isInProgress) ...[
              SizedBox(height: 20.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 8.h,
                children: [
                  _buildModernProgressButton(workOrder, 25, '25%'),
                  _buildModernProgressButton(workOrder, 50, '50%'),
                  _buildModernProgressButton(workOrder, 75, '75%'),
                  _buildModernProgressButton(workOrder, 100, 'Complete'),
                ],
              ),
            ],

            SizedBox(height: 20.h),

            // Cost information
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildCostItem('Labor Cost', workOrder.laborCost),
                      ),
                      Expanded(
                        child: _buildCostItem('Parts Cost', workOrder.partsCost),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient.scale(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Cost',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'Rp ${workOrder.totalCost.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostItem(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Rp ${amount.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildModernProgressButton(WorkOrder workOrder, int progress, String label) {
    final isEnabled = workOrder.progress < progress;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: isEnabled ? [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? () => _updateProgress(workOrder, progress) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? AppTheme.primaryColor : Colors.grey.shade300,
          foregroundColor: isEnabled ? Colors.white : Colors.grey.shade500,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          minimumSize: Size(0, 40.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: isEnabled ? 2 : 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}