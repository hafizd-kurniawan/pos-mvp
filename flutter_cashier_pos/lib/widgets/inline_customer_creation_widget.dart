import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/logger_service.dart';
import '../utils/app_theme.dart';

class InlineCustomerCreationWidget extends StatefulWidget {
  final Function(Customer) onCustomerCreated;
  final VoidCallback? onCancel;

  const InlineCustomerCreationWidget({
    Key? key,
    required this.onCustomerCreated,
    this.onCancel,
  }) : super(key: key);

  @override
  State<InlineCustomerCreationWidget> createState() => _InlineCustomerCreationWidgetState();
}

class _InlineCustomerCreationWidgetState extends State<InlineCustomerCreationWidget> {
  final _formKey = GlobalKey<FormState>();
  final CustomerService _customerService = CustomerService();
  final LoggerService _logger = LoggerService();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isCreating = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    _logger.userAction('Create new customer inline', data: {
      'firstName': _firstNameController.text,
      'phone': _phoneController.text,
    });

    try {
      final response = await _customerService.createCustomer(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isNotEmpty 
            ? _lastNameController.text.trim() 
            : 'N/A', // Backend requires last_name
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (response.isSuccess && response.data != null) {
        _logger.info('Customer created successfully inline', tag: 'CustomerCreation', data: {
          'customerId': response.data!.id,
          'customerCode': response.data!.customerCode,
        });
        
        widget.onCustomerCreated(response.data!);
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e, stackTrace) {
      _logger.error('Inline customer creation failed', tag: 'CustomerCreation', 
                   error: e, stackTrace: stackTrace);
      _showErrorSnackBar('Failed to create customer: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.person_add, color: AppTheme.primaryColor, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Create New Customer',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Spacer(),
                  if (widget.onCancel != null)
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                ],
              ),
              SizedBox(height: 16.h),

              // Name fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name (Optional)',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Phone field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '081234567890',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'customer@email.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Address field
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Address (Optional)',
                  hintText: 'Customer address...',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
              SizedBox(height: 24.h),

              // Action buttons
              Row(
                children: [
                  if (widget.onCancel != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isCreating ? null : widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    flex: widget.onCancel != null ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isCreating
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text('Create Customer'),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}