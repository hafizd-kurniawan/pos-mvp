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
import '../widgets/customer_form_dialog.dart';
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
  final _vehicleFilterController = TextEditingController();
  
  bool _isLoading = false;
  List<Car> _availableCars = [];
  List<Car> _filteredCars = [];
  Car? _selectedCar;
  Customer? _selectedCustomer;
  String _selectedPaymentMethod = 'cash';
  double _totalAmount = 0.0;
  String? _selectedBrandFilter;
  String? _selectedFuelTypeFilter;
  String? _selectedTransmissionFilter;
  
  @override
  void initState() {
    super.initState();
    _loadAvailableCars();
    _setupAmountListeners();
    _setupVehicleFilterListener();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _vehicleFilterController.dispose();
    super.dispose();
  }

  void _setupAmountListeners() {
    _amountController.addListener(_calculateTotal);
    _discountController.addListener(_calculateTotal);
  }

  void _setupVehicleFilterListener() {
    _vehicleFilterController.addListener(() {
      _filterVehicles();
    });
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
        _filteredCars = response.data!;
      });
    } else {
      _showErrorSnackBar(response.message);
    }
    
    setState(() => _isLoading = false);
  }

  void _filterVehicles() {
    final query = _vehicleFilterController.text.toLowerCase();
    setState(() {
      _filteredCars = _availableCars.where((car) {
        final matchesText = query.isEmpty || 
            car.displayName.toLowerCase().contains(query) ||
            car.licensePlate.toLowerCase().contains(query) ||
            car.brand.toLowerCase().contains(query) ||
            car.model.toLowerCase().contains(query) ||
            car.color.toLowerCase().contains(query);
            
        final matchesBrand = _selectedBrandFilter == null || car.brand == _selectedBrandFilter;
        final matchesFuelType = _selectedFuelTypeFilter == null || car.fuelType == _selectedFuelTypeFilter;
        final matchesTransmission = _selectedTransmissionFilter == null || car.transmission == _selectedTransmissionFilter;
        
        return matchesText && matchesBrand && matchesFuelType && matchesTransmission;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _vehicleFilterController.clear();
      _selectedBrandFilter = null;
      _selectedFuelTypeFilter = null;
      _selectedTransmissionFilter = null;
      _filteredCars = _availableCars;
    });
  }

  void _onCarSelected(Car car) {
    setState(() {
      _selectedCar = car;
      if (car.sellingPrice != null) {
        _amountController.text = car.sellingPrice!.toStringAsFixed(0);
      }
    });
  }

  Future<void> _showCarDetails(Car car) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(car.displayName),
        content: SizedBox(
          width: 400.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car image
              if (car.primaryPhotoUrl != null)
                Container(
                  height: 200.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      car.primaryPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.directions_car,
                        size: 48.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              
              SizedBox(height: 16.h),
              
              // Car details
              _buildDetailRow('License Plate', car.licensePlate),
              _buildDetailRow('Brand', car.brand),
              _buildDetailRow('Model', car.model),
              _buildDetailRow('Year', car.year.toString()),
              _buildDetailRow('Color', car.color),
              _buildDetailRow('Fuel Type', car.fuelType),
              _buildDetailRow('Transmission', car.transmission),
              _buildDetailRow('Mileage', '${car.mileage} km'),
              if (car.sellingPrice != null)
                _buildDetailRow('Selling Price', 'Rp ${car.sellingPrice!.toStringAsFixed(0)}'),
              _buildDetailRow('Status', car.statusDisplayName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _onCarSelected(car);
            },
            child: const Text('Select Vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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
        
        // Show success notification
        _showSuccessSnackBar('Sale completed successfully! Invoice: ${invoice.invoiceNumber}');
        
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedCar = null;
      _selectedCustomer = null;
      _selectedPaymentMethod = 'cash';
      _totalAmount = 0.0;
      _vehicleFilterController.clear();
      _selectedBrandFilter = null;
      _selectedFuelTypeFilter = null;
      _selectedTransmissionFilter = null;
      _filteredCars = _availableCars;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 28.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Sale Completed',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: 400.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildInvoiceDetailRow('Invoice Number', invoice.invoiceNumber),
                    _buildInvoiceDetailRow('Customer', _selectedCustomer!.name),
                    _buildInvoiceDetailRow('Vehicle', _selectedCar!.displayName),
                    _buildInvoiceDetailRow('License Plate', _selectedCar!.licensePlate),
                    _buildInvoiceDetailRow('Total Amount', 'Rp ${invoice.totalAmount.toStringAsFixed(0)}'),
                    _buildInvoiceDetailRow('Payment Method', invoice.paymentMethodDisplayName),
                    _buildInvoiceDetailRow('Date', DateTime.now().toString().split(' ')[0]),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'Close',
              style: TextStyle(fontSize: 16.sp),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _generateInvoiceReceipt(invoice);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGradient.colors.first,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            icon: Icon(Icons.receipt_long, size: 18.sp, color: Colors.white),
            label: Text(
              'Generate Receipt',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generateInvoiceReceipt(Invoice invoice) {
    _showInfoSnackBar('Receipt generation feature will be implemented soon. Invoice ${invoice.invoiceNumber} recorded successfully.');
    // TODO: Implement PDF generation and printing
    // This could connect to a receipt printing service or generate PDF
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

  Widget _buildCustomerSelector() {
    return Column(
      children: [
        if (_selectedCustomer != null) ...[
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      _selectedCustomer!.name.substring(0, 1).toUpperCase(),
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
                          _selectedCustomer!.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _selectedCustomer!.phone,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Code: ${_selectedCustomer!.customerCode}',
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
                        _selectedCustomer = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: InkWell(
              onTap: _showCustomerSelectionDialog,
              borderRadius: BorderRadius.circular(8.r),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Select Customer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16.sp,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showCustomerSelectionDialog() async {
    final TextEditingController searchController = TextEditingController();
    List<Customer> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Customer'),
          content: SizedBox(
            width: 400.w,
            height: 500.h,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by name or phone',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: isSearching
                        ? const CircularProgressIndicator()
                        : null,
                  ),
                  onChanged: (value) async {
                    if (value.trim().isEmpty) {
                      setDialogState(() {
                        searchResults.clear();
                      });
                      return;
                    }

                    setDialogState(() => isSearching = true);

                    try {
                      final response = await _customerService.getCustomers(search: value);
                      if (response.isSuccess && response.data != null) {
                        setDialogState(() {
                          searchResults = response.data!;
                        });
                      }
                    } catch (e) {
                      // Handle error
                    } finally {
                      setDialogState(() => isSearching = false);
                    }
                  },
                ),
                
                SizedBox(height: 16.h),
                
                // Create new customer button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await showDialog<Customer>(
                        context: context,
                        builder: (context) => const CustomerFormDialog(),
                      );
                      if (result != null) {
                        Navigator.of(context).pop();
                        _onCustomerSelected(result);
                      }
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Create New Customer'),
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Search results
                Expanded(
                  child: searchResults.isEmpty
                      ? Center(
                          child: Text(
                            searchController.text.isEmpty
                                ? 'Start typing to search customers'
                                : 'No customers found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final customer = searchResults[index];
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
                              title: Text(customer.name),
                              subtitle: Text(customer.phone),
                              onTap: () {
                                Navigator.of(context).pop();
                                _onCustomerSelected(customer);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleFilters() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _vehicleFilterController,
              decoration: InputDecoration(
                labelText: 'Search vehicles',
                hintText: 'Search by brand, model, license plate...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _vehicleFilterController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _vehicleFilterController.clear();
                        },
                      )
                    : null,
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Filter dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBrandFilter,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _getUniqueBrands()
                        .map((brand) => DropdownMenuItem(
                              value: brand,
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  brand ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBrandFilter = value;
                      });
                      _filterVehicles();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFuelTypeFilter,
                    decoration: const InputDecoration(
                      labelText: 'Fuel Type',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _getUniqueFuelTypes()
                        .map((fuel) => DropdownMenuItem(
                              value: fuel,
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  fuel ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFuelTypeFilter = value;
                      });
                      _filterVehicles();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTransmissionFilter,
                    decoration: const InputDecoration(
                      labelText: 'Transmission',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _getUniqueTransmissions()
                        .map((trans) => DropdownMenuItem(
                              value: trans,
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  trans ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTransmissionFilter = value;
                      });
                      _filterVehicles();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getUniqueBrands() {
    return _availableCars
        .map((car) => car.brand)
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList()
        ..sort();
  }

  List<String> _getUniqueFuelTypes() {
    return _availableCars
        .map((car) => car.fuelType)
        .where((fuel) => fuel.isNotEmpty)
        .toSet()
        .toList()
        ..sort();
  }

  List<String> _getUniqueTransmissions() {
    return _availableCars
        .map((car) => car.transmission)
        .where((trans) => trans.isNotEmpty)
        .toSet()
        .toList()
        ..sort();
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
                _buildCustomerSelector(),
                
                SizedBox(height: 24.h),
                
                // Vehicle selection with filters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Vehicle',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: Icon(Icons.clear_all, size: 18.sp),
                      label: const Text('Clear Filters'),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                // Vehicle filters
                _buildVehicleFilters(),
                
                SizedBox(height: 16.h),
                
                if (_filteredCars.isEmpty)
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
                      crossAxisCount: 4, // Fixed 4 columns as requested
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.75, // Adjusted for better card proportions
                    ),
                    itemCount: _filteredCars.length,
                    itemBuilder: (context, index) {
                      final car = _filteredCars[index];
                      return GestureDetector(
                        onLongPress: () => _showCarDetails(car),
                        child: CarSelectionCard(
                          car: car,
                          isSelected: _selectedCar?.id == car.id,
                          onTap: () => _onCarSelected(car),
                        ),
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