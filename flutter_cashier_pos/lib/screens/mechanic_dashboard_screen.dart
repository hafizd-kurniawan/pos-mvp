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
      appBar: AppBar(
        title: const Text('Mechanic Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyWorkOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: RefreshIndicator(
          onRefresh: _loadMyWorkOrders,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30.r,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                Icons.build,
                                size: 30.sp,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back, ${user?.name ?? 'Mechanic'}!',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Mechanic Workshop',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Statistics Cards
                ResponsiveRowColumn(
                  layout: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
                      ? ResponsiveRowColumnType.ROW
                      : ResponsiveRowColumnType.COLUMN,
                  rowMainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: _buildStatCard(
                        'Pending Orders',
                        pendingOrders.toString(),
                        Icons.pending_actions,
                        AppTheme.warningColor,
                      ),
                    ),
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: _buildStatCard(
                        'In Progress',
                        inProgressOrders.toString(),
                        Icons.build,
                        AppTheme.primaryColor,
                      ),
                    ),
                    ResponsiveRowColumnItem(
                      rowFlex: 1,
                      child: _buildStatCard(
                        'Completed Today',
                        completedToday.toString(),
                        Icons.check_circle,
                        AppTheme.successColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Work Orders Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Work Orders',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _loadMyWorkOrders,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16.h),

                        if (_errorMessage != null)
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppTheme.errorColor.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppTheme.errorColor,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: AppTheme.errorColor,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_myWorkOrders.isEmpty)
                          Container(
                            padding: EdgeInsets.all(40.w),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.work_off,
                                  size: 64.sp,
                                  color: Colors.grey.shade400,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No work orders assigned',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'You currently have no work orders assigned to you.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: _myWorkOrders.map((workOrder) {
                              return _buildWorkOrderCard(workOrder);
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.all(4.w),
      child: Card(
        elevation: 2,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32.sp,
                color: color,
              ),
              SizedBox(height: 12.h),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildWorkOrderCard(WorkOrder workOrder) {
    Color statusColor;
    switch (workOrder.status) {
      case 'pending':
        statusColor = AppTheme.warningColor;
        break;
      case 'in_progress':
        statusColor = AppTheme.primaryColor;
        break;
      case 'completed':
        statusColor = AppTheme.successColor;
        break;
      case 'cancelled':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        workOrder.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    workOrder.statusDisplayName,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Progress bar
            Row(
              children: [
                Text(
                  'Progress: ${workOrder.progress}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: LinearProgressIndicator(
                    value: workOrder.progress / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Progress buttons (for in-progress orders)
            if (workOrder.isInProgress)
              Wrap(
                spacing: 8.w,
                children: [
                  _buildProgressButton(workOrder, 25, '25%'),
                  _buildProgressButton(workOrder, 50, '50%'),
                  _buildProgressButton(workOrder, 75, '75%'),
                  _buildProgressButton(workOrder, 100, 'Complete'),
                ],
              ),

            SizedBox(height: 12.h),

            // Cost information
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Labor: Rp ${workOrder.laborCost.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Parts: Rp ${workOrder.partsCost.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Total: Rp ${workOrder.totalCost.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressButton(WorkOrder workOrder, int progress, String label) {
    return ElevatedButton(
      onPressed: workOrder.progress < progress 
          ? () => _updateProgress(workOrder, progress)
          : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        minimumSize: Size(0, 32.h),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp),
      ),
    );
  }
}