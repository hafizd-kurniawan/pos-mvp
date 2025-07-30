import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../models/invoice.dart';
import '../services/sales_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/placeholder_widgets.dart';
import '../widgets/placeholder_widgets.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  const InvoiceScreen({super.key});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> 
    with SingleTickerProviderStateMixin {
  final SalesService _salesService = SalesService();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  List<Invoice> _invoices = [];
  bool _isLoading = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  
  // Filter parameters
  String? _selectedStatus;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadInvoices(isRefresh: true);
    }
  }

  Future<void> _loadInvoices({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _invoices.clear();
        _hasMoreData = true;
      });
    }

    setState(() => _isLoading = true);

    try {
      final response = await _salesService.getSalesInvoices(
        page: _currentPage,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _selectedStatus,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          if (isRefresh) {
            _invoices = response.data!;
          } else {
            _invoices.addAll(response.data!);
          }
          _hasMoreData = response.pagination?.hasNext ?? false;
          if (_hasMoreData) _currentPage++;
        });
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error loading invoices: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => InvoiceFilterDialog(
        selectedStatus: _selectedStatus,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedStatus = result['status'];
        _fromDate = result['fromDate'];
        _toDate = result['toDate'];
      });
      
      await _loadInvoices(isRefresh: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _fromDate = null;
      _toDate = null;
      _searchController.clear();
    });
    _loadInvoices(isRefresh: true);
  }

  Future<void> _showInvoiceDetails(Invoice invoice) async {
    await showDialog(
      context: context,
      builder: (context) => InvoiceDetailsDialog(invoice: invoice),
    );
    
    // Refresh the invoice list to get updated status
    _loadInvoices(isRefresh: true);
  }

  Future<void> _searchInvoiceByNumber() async {
    final invoiceNumber = _searchController.text.trim();
    if (invoiceNumber.isEmpty) {
      _loadInvoices(isRefresh: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _salesService.getInvoiceByNumber(invoiceNumber);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _invoices = [response.data!];
          _hasMoreData = false;
        });
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error searching invoice: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedStatus != null) count++;
    if (_fromDate != null) count++;
    if (_toDate != null) count++;
    return count;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadInvoices(isRefresh: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Invoices'),
            Tab(text: 'Today'),
          ],
        ),
      ),
      
      body: LoadingOverlay(
        isLoading: _isLoading && _invoices.isEmpty,
        child: Column(
          children: [
            // Search and filter section
            Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by invoice number...',
                            prefixIcon: Icon(Icons.search, size: 20.sp),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 20.sp),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadInvoices(isRefresh: true);
                                    },
                                  )
                                : null,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchInvoiceByNumber(),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton.icon(
                        onPressed: _searchInvoiceByNumber,
                        icon: Icon(Icons.search, size: 18.sp),
                        label: const Text('Search'),
                      ),
                      SizedBox(width: 8.w),
                      Badge(
                        isLabelVisible: _activeFilterCount > 0,
                        label: Text(_activeFilterCount.toString()),
                        child: IconButton.filled(
                          onPressed: _showFilterDialog,
                          icon: Icon(Icons.tune, size: 20.sp),
                        ),
                      ),
                    ],
                  ),
                  
                  // Active filters display
                  if (_activeFilterCount > 0) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Text(
                          'Filters applied:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Wrap(
                            spacing: 4.w,
                            children: [
                              if (_selectedStatus != null)
                                Chip(
                                  label: Text(_selectedStatus!),
                                  deleteIcon: Icon(Icons.close, size: 16.sp),
                                  onDeleted: () {
                                    setState(() => _selectedStatus = null);
                                    _loadInvoices(isRefresh: true);
                                  },
                                ),
                              if (_fromDate != null)
                                Chip(
                                  label: Text('From: ${_fromDate!.toString().split(' ')[0]}'),
                                  deleteIcon: Icon(Icons.close, size: 16.sp),
                                  onDeleted: () {
                                    setState(() => _fromDate = null);
                                    _loadInvoices(isRefresh: true);
                                  },
                                ),
                              if (_toDate != null)
                                Chip(
                                  label: Text('To: ${_toDate!.toString().split(' ')[0]}'),
                                  deleteIcon: Icon(Icons.close, size: 16.sp),
                                  onDeleted: () {
                                    setState(() => _toDate = null);
                                    _loadInvoices(isRefresh: true);
                                  },
                                ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: Icon(Icons.clear_all, size: 16.sp),
                          label: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Invoice count
            if (_invoices.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                color: Colors.grey.shade50,
                child: Text(
                  '${_invoices.length} invoices found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            
            // Invoice list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All invoices tab
                  _buildInvoiceList(),
                  
                  // Today invoices tab
                  _buildInvoiceList(todayOnly: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceList({bool todayOnly = false}) {
    var displayInvoices = _invoices;
    
    if (todayOnly) {
      final today = DateTime.now();
      displayInvoices = _invoices.where((invoice) {
        return invoice.createdAt.year == today.year &&
               invoice.createdAt.month == today.month &&
               invoice.createdAt.day == today.day;
      }).toList();
    }

    if (displayInvoices.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 64.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              todayOnly ? 'No invoices today' : 'No invoices found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              todayOnly 
                  ? 'Start making sales to see invoices here'
                  : 'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: displayInvoices.length + (!todayOnly && _hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayInvoices.length) {
          // Load more indicator (only for all invoices tab)
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _loadInvoices(),
                child: _isLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Load More'),
              ),
            ),
          );
        }

        final invoice = displayInvoices[index];
        return InvoiceCard(
          invoice: invoice,
          onTap: () => _showInvoiceDetails(invoice),
        );
      },
    );
  }
}