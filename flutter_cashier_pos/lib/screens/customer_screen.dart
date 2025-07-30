import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_form_dialog.dart';

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key});

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Customer> _customers = [];
  bool _isLoading = false;
  bool _isSearching = false;
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _customers.clear();
        _hasMoreData = true;
      });
    }

    setState(() => _isLoading = true);

    try {
      final response = await _customerService.getCustomers(
        page: _currentPage,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          if (isRefresh) {
            _customers = response.data!;
          } else {
            _customers.addAll(response.data!);
          }
          _hasMoreData = response.pagination?.hasNext ?? false;
          if (_hasMoreData) _currentPage++;
        });
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error loading customers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchCustomers() async {
    setState(() => _isSearching = true);
    await _loadCustomers(isRefresh: true);
    setState(() => _isSearching = false);
  }

  Future<void> _searchByPhone(String phone) async {
    setState(() => _isLoading = true);

    try {
      final response = await _customerService.searchCustomersByPhone(phone);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _customers = response.data!;
          _hasMoreData = false;
        });
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error searching customers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddCustomerDialog() async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => const CustomerFormDialog(),
    );

    if (result != null) {
      _showSuccessSnackBar('Customer created successfully');
      await _loadCustomers(isRefresh: true);
    }
  }

  Future<void> _showEditCustomerDialog(Customer customer) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => CustomerFormDialog(customer: customer),
    );

    if (result != null) {
      _showSuccessSnackBar('Customer updated successfully');
      await _loadCustomers(isRefresh: true);
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCustomers(isRefresh: true),
          ),
        ],
      ),
      
      body: LoadingOverlay(
        isLoading: _isLoading && _customers.isEmpty,
        child: Column(
          children: [
            // Search section
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
                            hintText: 'Search by name, email, or phone...',
                            prefixIcon: Icon(Icons.search, size: 20.sp),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 20.sp),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchCustomers();
                                    },
                                  )
                                : null,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchCustomers(),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton.icon(
                        onPressed: _isSearching ? null : _searchCustomers,
                        icon: _isSearching
                            ? SizedBox(
                                width: 16.w,
                                height: 16.h,
                                child: const CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.search, size: 18.sp),
                        label: const Text('Search'),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Quick phone search
                  Text(
                    'Quick Search by Phone:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    children: ['08', '081', '082', '083', '085', '087', '089'].map(
                      (prefix) => ActionChip(
                        label: Text(prefix),
                        onPressed: () {
                          _searchController.text = prefix;
                          _searchByPhone(prefix);
                        },
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
            
            // Customer count
            if (_customers.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                color: Colors.grey.shade50,
                child: Text(
                  '${_customers.length} customers found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            
            // Customer list
            Expanded(
              child: _customers.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64.sp,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No customers found',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Try adjusting your search or add a new customer',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: _customers.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _customers.length) {
                          // Load more indicator
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _loadCustomers(),
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

                        final customer = _customers[index];
                        return CustomerCard(
                          customer: customer,
                          onTap: () => _showEditCustomerDialog(customer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerDialog,
        icon: Icon(Icons.person_add, size: 20.sp),
        label: const Text('Add Customer'),
      ),
    );
  }
}