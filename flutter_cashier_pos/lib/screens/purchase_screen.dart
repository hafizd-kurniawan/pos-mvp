import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../constants/app_constants.dart';
import '../models/car.dart';
import '../models/customer.dart';
import '../models/user.dart';
import '../services/purchase_service.dart';
import '../services/customer_service.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';
import '../widgets/customer_selection_widget.dart';
import '../widgets/car_selection_card.dart';
import '../widgets/loading_overlay.dart';
import '../utils/app_theme.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> with TickerProviderStateMixin {
  final PurchaseService _purchaseService = PurchaseService();
  final CustomerService _customerService = CustomerService();
  final CarService _carService = CarService();
  final AuthService _authService = AuthService();
  final LoggerService _logger = logger;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected data
  Customer? _selectedCustomer;
  Car? _selectedCar;
  String _selectedPaymentMethod = AppConstants.paymentMethods[0];
  
  // State
  bool _isLoading = false;
  List<Car> _availableCars = [];
  bool _loadingCars = false;
  User? _currentUser;

  // Animation controllers
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.getCurrentUser();
    _initializeAnimations();
    _loadAvailableCars();
    _logger.navigationEvent('Dashboard', 'Purchase Screen');
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCars() async {
    if (_loadingCars) return;

    setState(() => _loadingCars = true);
    _logger.userAction('Load available cars for purchase');

    try {
      final response = await _carService.getCars(status: 'available');
      
      if (response.success && response.data != null) {
        setState(() {
          _availableCars = response.data!;
        });
        _logger.info('Available cars loaded for purchase', tag: 'Purchase', 
                    data: {'count': _availableCars.length});
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load available cars', tag: 'Purchase', 
                   error: e, stackTrace: stackTrace);
      _showErrorSnackBar('Failed to load available cars: $e');
    } finally {
      setState(() => _loadingCars = false);
    }
  }

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate() || _selectedCar == null || _currentUser == null) {
      _logger.warning('Purchase form validation failed', tag: 'Purchase');
      return;
    }

    setState(() => _isLoading = true);
    _logger.userAction('Submit purchase', data: {
      'carId': _selectedCar!.id,
      'amount': double.tryParse(_amountController.text),
      'paymentMethod': _selectedPaymentMethod,
    });

    try {
      final request = CreatePurchaseRequest(
        customerId: _selectedCustomer?.id,
        carId: _selectedCar!.id,
        amount: double.parse(_amountController.text),
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.trim(),
        createdBy: _currentUser!.id,
      );

      final response = await _purchaseService.createPurchase(request);

      if (response.success && response.data != null) {
        _logger.info('Purchase completed successfully', tag: 'Purchase', data: {
          'invoiceNumber': response.data!['invoice']?['invoice_number'],
          'carId': _selectedCar!.id,
        });

        _showSuccessDialog(response.data!);
        _resetForm();
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e, stackTrace) {
      _logger.error('Purchase submission failed', tag: 'Purchase', 
                   error: e, stackTrace: stackTrace);
      _showErrorSnackBar('Purchase failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _notesController.clear();
    setState(() {
      _selectedCustomer = null;
      _selectedCar = null;
      _selectedPaymentMethod = AppConstants.paymentMethods[0];
    });
    _loadAvailableCars(); // Refresh car list
  }

  void _showSuccessDialog(Map<String, dynamic> purchaseData) {
    final invoice = purchaseData['invoice'];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 24.sp),
            SizedBox(width: 8.w),
            Text('Purchase Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purchase Invoice: ${invoice['invoice_number']}'),
            SizedBox(height: 8.h),
            Text('Amount: Rp ${_formatCurrency(invoice['total_amount'])}'),
            SizedBox(height: 8.h),
            Text('Payment: $_selectedPaymentMethod'),
            if (_selectedCustomer != null) ...[
              SizedBox(height: 8.h),
              Text('From: ${_selectedCustomer!.name}'),
            ],
            SizedBox(height: 16.h),
            Text('Vehicle is now in repair status and ready for workshop assignment.',
                 style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continue'),
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

  String _formatCurrency(dynamic amount) {
    final value = double.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Purchase Vehicle',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(),
                  SizedBox(height: 24.h),

                  // Customer Selection (Optional)
                  _buildCustomerSelection(),
                  SizedBox(height: 20.h),

                  // Car Selection
                  _buildCarSelection(),
                  SizedBox(height: 20.h),

                  // Purchase Details
                  _buildPurchaseDetails(),
                  SizedBox(height: 32.h),

                  // Submit Button
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.white, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Purchase Vehicle from Customer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Buy vehicle from customer and automatically generate purchase invoice',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppTheme.primaryColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Customer (Optional)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            CustomerSelectionWidget(
              selectedCustomer: _selectedCustomer,
              onCustomerSelected: (customer) {
                setState(() => _selectedCustomer = customer);
                _logger.userAction('Customer selected for purchase', data: {
                  'customerId': customer?.id,
                  'customerName': customer?.name,
                });
              },
              hintText: 'Select customer selling the vehicle (optional)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: AppTheme.primaryColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Select Vehicle to Purchase',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                if (_loadingCars)
                  SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            
            if (_availableCars.isEmpty && !_loadingCars)
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[600], size: 32.sp),
                      SizedBox(height: 8.h),
                      Text(
                        'No vehicles available for purchase',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 200.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableCars.length,
                  itemBuilder: (context, index) {
                    final car = _availableCars[index];
                    final isSelected = _selectedCar?.id == car.id;
                    
                    return Container(
                      width: 280.w,
                      margin: EdgeInsets.only(right: 12.w),
                      child: CarSelectionCard(
                        car: car,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedCar = car);
                          _logger.userAction('Car selected for purchase', data: {
                            'carId': car.id,
                            'brand': car.brand,
                            'model': car.model,
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseDetails() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: AppTheme.primaryColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Purchase Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Purchase Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Purchase Amount (Rp)',
                hintText: 'Enter negotiated purchase price',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Purchase amount is required';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // Payment Method
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              items: AppConstants.paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value!);
                _logger.userAction('Payment method selected', data: {'method': value});
              },
            ),
            SizedBox(height: 16.h),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Additional notes about the purchase...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isFormValid = _selectedCar != null && _amountController.text.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: isFormValid ? _submitPurchase : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Complete Purchase',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}