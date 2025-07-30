import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:go_router/go_router.dart';
import '../models/car.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/api_models.dart';
import '../services/car_service.dart';
import '../services/customer_service.dart';
import '../services/sales_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/car_selection_card.dart';
import '../widgets/customer_selection_widget.dart';
import '../widgets/payment_method_selector.dart';
import '../constants/app_constants.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final CarService _carService = CarService();
  final CustomerService _customerService = CustomerService();
  final SalesService _salesService = SalesService();
  final AuthService _authService = AuthService();
  
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _discountController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  List<Car> _availableCars = [];
  Car? _selectedCar;
  Customer? _selectedCustomer;
  String _selectedPaymentMethod = 'cash';
  double _totalAmount = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadAvailableCars();
    _setupAmountListeners();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setupAmountListeners() {
    _amountController.addListener(_calculateTotal);
    _discountController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    setState(() {
      _totalAmount = amount - discount;
    });
  }

  Future<void> _loadAvailableCars() async {
    setState(() => _isLoading = true);
    
    final response = await _carService.getAvailableCars();
    if (response.isSuccess && response.data != null) {
      setState(() {
        _availableCars = response.data!;
      });
    } else {
      _showErrorSnackBar(response.message);
    }
    
    setState(() => _isLoading = false);
  }

  void _onCarSelected(Car car) {
    setState(() {
      _selectedCar = car;
      if (car.sellingPrice != null) {
        _amountController.text = car.sellingPrice!.toStringAsFixed(0);
      }
    });
  }

  void _onCustomerSelected(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
    });
  }

  void _onPaymentMethodChanged(String method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  Future<void> _processSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCar == null) {
      _showErrorSnackBar('Please select a car');
      return;
    }
    if (_selectedCustomer == null) {
      _showErrorSnackBar('Please select a customer');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }

      final saleRequest = CreateSaleRequest(
        customerId: _selectedCustomer!.id,
        carId: _selectedCar!.id,
        amount: double.parse(_amountController.text),
        discountAmount: double.tryParse(_discountController.text) ?? 0.0,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdBy: currentUser.id,
      );

      final response = await _salesService.createSale(saleRequest);

      if (response.isSuccess && response.data != null) {
        final invoice = response.data!;
        
        // Show success dialog with option to print invoice
        await _showSaleSuccessDialog(invoice);
        
        // Reset form
        _resetForm();
        
        // Reload available cars
        await _loadAvailableCars();
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error processing sale: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedCar = null;
      _selectedCustomer = null;
      _selectedPaymentMethod = 'cash';
      _totalAmount = 0.0;
    });
    _amountController.clear();
    _discountController.clear();
    _notesController.clear();
  }

  Future<void> _showSaleSuccessDialog(Invoice invoice) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.successColor,
              size: 28.sp,
            ),
            SizedBox(width: 8.w),
            const Text('Sale Completed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice Number: ${invoice.invoiceNumber}'),
            SizedBox(height: 8.h),
            Text('Customer: ${_selectedCustomer!.name}'),
            SizedBox(height: 8.h),
            Text('Vehicle: ${_selectedCar!.displayName}'),
            SizedBox(height: 8.h),
            Text('Total Amount: Rp ${invoice.totalAmount.toStringAsFixed(0)}'),
            SizedBox(height: 8.h),
            Text('Payment: ${invoice.paymentMethodDisplayName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement PDF generation/printing
              _showInfoSnackBar('Invoice printing feature coming soon');
            },
            icon: Icon(Icons.print, size: 18.sp),
            label: const Text('Print Invoice'),
          ),
        ],
      ),
    );
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.infoColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableCars,
          ),
        ],
      ),
      
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer selection
                Text(
                  'Select Customer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                CustomerSelectionWidget(
                  selectedCustomer: _selectedCustomer,
                  onCustomerSelected: _onCustomerSelected,
                ),
                
                SizedBox(height: 24.h),
                
                // Car selection
                Text(
                  'Select Vehicle',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                
                if (_availableCars.isEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48.sp,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'No vehicles available for sale',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 2 : 1,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _availableCars.length,
                    itemBuilder: (context, index) {
                      final car = _availableCars[index];
                      return CarSelectionCard(
                        car: car,
                        isSelected: _selectedCar?.id == car.id,
                        onTap: () => _onCarSelected(car),
                      );
                    },
                  ),
                
                if (_selectedCar != null) ...[
                  SizedBox(height: 24.h),
                  
                  // Sale details
                  Text(
                    'Sale Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // Amount field
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Sale Amount (Rp)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Amount is required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Discount field
                  TextFormField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      labelText: 'Discount Amount (Rp) - Optional',
                      prefixIcon: Icon(Icons.local_offer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final discount = double.tryParse(value);
                        if (discount == null || discount < 0) {
                          return 'Please enter a valid discount amount';
                        }
                        final amount = double.tryParse(_amountController.text) ?? 0.0;
                        if (discount >= amount) {
                          return 'Discount cannot be greater than or equal to amount';
                        }
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Payment method
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  PaymentMethodSelector(
                    selectedMethod: _selectedPaymentMethod,
                    onMethodChanged: _onPaymentMethodChanged,
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Notes field
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Total amount display
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Amount',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Rp ${_totalAmount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Process sale button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _processSale,
                      icon: Icon(Icons.sell, size: 20.sp),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: Text(
                          'Process Sale',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}