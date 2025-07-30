import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../widgets/loading_overlay.dart';

class CustomerFormDialog extends StatefulWidget {
  final Customer? customer; // For editing existing customer

  const CustomerFormDialog({super.key, this.customer});

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _identityNumberController = TextEditingController();
  
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;
  String _selectedIdentityType = 'KTP';
  
  final List<String> _identityTypes = ['KTP', 'SIM', 'Passport', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final customer = widget.customer!;
    _nameController.text = customer.name;
    _emailController.text = customer.email;
    _phoneController.text = customer.phone;
    _addressController.text = customer.address ?? '';
    _identityNumberController.text = customer.identityNumber ?? '';
    _selectedIdentityType = customer.identityType ?? 'KTP';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _identityNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.customer == null) {
        // Create new customer
        final response = await _customerService.createCustomer(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          identityType: _selectedIdentityType,
          identityNumber: _identityNumberController.text.trim().isEmpty ? null : _identityNumberController.text.trim(),
        );

        if (response.isSuccess && response.data != null) {
          Navigator.of(context).pop(response.data);
        } else {
          _showErrorSnackBar(response.message);
        }
      } else {
        // Update existing customer
        final response = await _customerService.updateCustomer(
          customerId: widget.customer!.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          identityType: _selectedIdentityType,
          identityNumber: _identityNumberController.text.trim().isEmpty ? null : _identityNumberController.text.trim(),
        );

        if (response.isSuccess && response.data != null) {
          Navigator.of(context).pop(response.data);
        } else {
          _showErrorSnackBar(response.message);
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error saving customer: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: LoadingOverlay(
        isLoading: _isLoading,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 500.w,
            maxHeight: 600.h,
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.person_add,
                    size: 24.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    widget.customer == null ? 'Add New Customer' : 'Edit Customer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24.h),
              
              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // Phone field
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number *',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            return null;
                          },
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // Address field
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address (Optional)',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // Identity type dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedIdentityType,
                          decoration: const InputDecoration(
                            labelText: 'Identity Type',
                            prefixIcon: Icon(Icons.card_membership),
                          ),
                          items: _identityTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedIdentityType = value!;
                            });
                          },
                        ),
                        
                        SizedBox(height: 16.h),
                        
                        // Identity number field
                        TextFormField(
                          controller: _identityNumberController,
                          decoration: InputDecoration(
                            labelText: '$_selectedIdentityType Number (Optional)',
                            prefixIcon: const Icon(Icons.badge),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCustomer,
                      child: Text(widget.customer == null ? 'Create' : 'Update'),
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