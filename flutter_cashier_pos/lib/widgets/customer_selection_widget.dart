import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/customer_form_dialog.dart';

class CustomerSelectionWidget extends StatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer) onCustomerSelected;
  final String? hintText;

  const CustomerSelectionWidget({
    super.key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.hintText,
  });

  @override
  State<CustomerSelectionWidget> createState() => _CustomerSelectionWidgetState();
}

class _CustomerSelectionWidgetState extends State<CustomerSelectionWidget> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Customer> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showResults = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await _customerService.getCustomers(search: query);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _searchResults = response.data!;
          _showResults = true;
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchByPhone(String phone) async {
    setState(() => _isSearching = true);

    try {
      final response = await _customerService.searchCustomersByPhone(phone);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _searchResults = response.data!;
          _showResults = true;
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _showResults = false;
      _searchController.text = '${customer.name} (${customer.phone})';
    });
    widget.onCustomerSelected(customer);
  }

  Future<void> _showCreateCustomerDialog() async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => const CustomerFormDialog(),
    );

    if (result != null) {
      _selectCustomer(result);
      _showSuccessSnackBar('Customer created successfully');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected customer display
        if (widget.selectedCustomer != null) ...[
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      widget.selectedCustomer!.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.selectedCustomer!.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.selectedCustomer!.phone,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Code: ${widget.selectedCustomer!.customerCode}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _showResults = false;
                      });
                      // Clear selection by calling with a dummy customer
                      // In real implementation, you'd modify the callback signature
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ],

        // Search field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Customer',
            hintText: widget.hintText ?? 'Type name, phone, or email...',
            prefixIcon: Icon(Icons.search, size: 20.sp),
            suffixIcon: _isSearching
                ? Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20.sp),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _showResults = false);
                        },
                      )
                    : null,
          ),
          onChanged: (value) {
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_searchController.text == value) {
                _searchCustomers(value);
              }
            });
          },
        ),

        SizedBox(height: 12.h),

        // Quick phone search
        Text(
          'Quick search by phone prefix:',
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

        SizedBox(height: 16.h),

        // Search results
        if (_showResults) ...[
          Text(
            'Search Results (${_searchResults.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            constraints: BoxConstraints(maxHeight: 300.h),
            child: Card(
              child: _searchResults.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 48.sp,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'No customers found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            ElevatedButton.icon(
                              onPressed: _showCreateCustomerDialog,
                              icon: Icon(Icons.person_add, size: 18.sp),
                              label: const Text('Add New Customer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final customer = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              customer.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.phone),
                              Text(
                                'Code: ${customer.customerCode}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _selectCustomer(customer),
                          trailing: const Icon(Icons.arrow_forward_ios),
                        );
                      },
                    ),
            ),
          ),
        ],

        // Create new customer button
        if (!_showResults || _searchResults.isEmpty) ...[
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showCreateCustomerDialog,
              icon: Icon(Icons.person_add, size: 20.sp),
              label: const Text('Create New Customer'),
            ),
          ),
        ],
      ],
    );
  }
}