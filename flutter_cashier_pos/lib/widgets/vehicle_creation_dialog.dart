import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/car.dart';
import '../models/customer.dart';
import '../services/car_service.dart';
import '../services/logger_service.dart';
import '../utils/app_theme.dart';

class VehicleCreationDialog extends StatefulWidget {
  final Customer? customer; // If creating for a specific customer
  final Function(Car) onVehicleCreated;
  final VoidCallback onCancel;
  final bool isForCustomer; // true if creating for customer, false for supplier

  const VehicleCreationDialog({
    Key? key,
    this.customer,
    required this.onVehicleCreated,
    required this.onCancel,
    this.isForCustomer = false,
  }) : super(key: key);

  @override
  State<VehicleCreationDialog> createState() => _VehicleCreationDialogState();
}

class _VehicleCreationDialogState extends State<VehicleCreationDialog> {
  final CarService _carService = CarService();
  final LoggerService _logger = logger;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _licensePlateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _vinController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _mileageController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Dropdown values
  String _selectedFuelType = 'gasoline';
  String _selectedTransmission = 'manual';
  String _selectedCondition = 'good';
  
  bool _isLoading = false;

  final List<String> _fuelTypes = ['gasoline', 'diesel', 'electric', 'hybrid'];
  final List<String> _transmissions = ['manual', 'automatic', 'cvt'];
  final List<String> _conditions = ['excellent', 'good', 'fair', 'poor'];

  @override
  void dispose() {
    _licensePlateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _vinController.dispose();
    _engineNumberController.dispose();
    _mileageController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      _logger.userAction('Create new vehicle', data: {
        'isForCustomer': widget.isForCustomer,
        'customerId': widget.customer?.id,
        'brand': _brandController.text,
        'model': _modelController.text,
      });

      final response = await _carService.createCar(
        licensePlate: _licensePlateController.text.trim(),
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text),
        color: _colorController.text.trim(),
        fuelType: _selectedFuelType,
        transmission: _selectedTransmission,
        mileage: int.tryParse(_mileageController.text) ?? 0,
        price: double.parse(_priceController.text),
        vin: _vinController.text.trim().isEmpty ? null : _vinController.text.trim(),
        engineNumber: _engineNumberController.text.trim().isEmpty ? null : _engineNumberController.text.trim(),
        condition: _selectedCondition,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        customerId: widget.isForCustomer ? widget.customer?.id : null,
      );

      if (response.success && response.data != null) {
        _logger.info('Vehicle created successfully', tag: 'VehicleCreation', data: {
          'vehicleId': response.data!.id,
          'customerId': widget.customer?.id,
          'isForCustomer': widget.isForCustomer,
        });

        widget.onVehicleCreated(response.data!);
        Navigator.of(context).pop();
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e, stackTrace) {
      _logger.error('Vehicle creation failed', tag: 'VehicleCreation', error: e, stackTrace: stackTrace);
      _showErrorSnackBar('Failed to create vehicle: $e');
    } finally {
      setState(() => _isLoading = false);
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
    return Dialog(
      child: Container(
        width: 600.w,
        constraints: BoxConstraints(maxHeight: 0.9.sh),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.white, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      widget.isForCustomer 
                          ? 'Add Customer Vehicle'
                          : 'Add Supplier Vehicle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Customer info (if applicable)
                      if (widget.isForCustomer && widget.customer != null) ...[
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: AppTheme.primaryColor, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Creating vehicle for: ${widget.customer!.name}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // Basic Information
                      _buildSectionTitle('Basic Information'),
                      SizedBox(height: 12.h),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _licensePlateController,
                              decoration: InputDecoration(
                                labelText: 'License Plate *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.confirmation_number),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'License plate is required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Year *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Year is required';
                                final year = int.tryParse(value!);
                                if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                                  return 'Enter a valid year';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brandController,
                              decoration: InputDecoration(
                                labelText: 'Brand *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.branding_watermark),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'Brand is required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              decoration: InputDecoration(
                                labelText: 'Model *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.directions_car),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'Model is required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _colorController,
                              decoration: InputDecoration(
                                labelText: 'Color *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.palette),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'Color is required' : null,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Price (Rp) *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Price is required';
                                final price = double.tryParse(value!);
                                if (price == null || price <= 0) {
                                  return 'Enter a valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Technical Specifications
                      _buildSectionTitle('Technical Specifications'),
                      SizedBox(height: 12.h),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedFuelType,
                              decoration: InputDecoration(
                                labelText: 'Fuel Type',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.local_gas_station),
                              ),
                              items: _fuelTypes.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.toUpperCase()),
                              )).toList(),
                              onChanged: (value) => setState(() => _selectedFuelType = value!),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedTransmission,
                              decoration: InputDecoration(
                                labelText: 'Transmission',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.settings),
                              ),
                              items: _transmissions.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.toUpperCase()),
                              )).toList(),
                              onChanged: (value) => setState(() => _selectedTransmission = value!),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mileageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Mileage (km)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.speed),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final mileage = int.tryParse(value);
                                  if (mileage == null || mileage < 0) {
                                    return 'Enter a valid mileage';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCondition,
                              decoration: InputDecoration(
                                labelText: 'Condition',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                                prefixIcon: Icon(Icons.assessment),
                              ),
                              items: _conditions.map((condition) => DropdownMenuItem(
                                value: condition,
                                child: Text(condition.toUpperCase()),
                              )).toList(),
                              onChanged: (value) => setState(() => _selectedCondition = value!),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Optional Information
                      _buildSectionTitle('Optional Information'),
                      SizedBox(height: 12.h),
                      
                      TextFormField(
                        controller: _vinController,
                        decoration: InputDecoration(
                          labelText: 'VIN Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                          prefixIcon: Icon(Icons.fingerprint),
                          hintText: '17 characters',
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length != 17) {
                            return 'VIN must be exactly 17 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12.h),
                      
                      TextFormField(
                        controller: _engineNumberController,
                        decoration: InputDecoration(
                          labelText: 'Engine Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                          prefixIcon: Icon(Icons.precision_manufacturing),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                          prefixIcon: Icon(Icons.notes),
                          hintText: 'Additional notes about the vehicle...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : widget.onCancel,
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Create Vehicle',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}