import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../models/car.dart';
import '../models/customer.dart';
import '../models/user.dart';
import '../services/purchase_service.dart';
import '../services/customer_service.dart';
import '../services/car_service.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';
import '../services/image_upload_service.dart';
import '../services/work_order_service.dart';
import '../services/user_service.dart';
import '../widgets/customer_selection_widget.dart';
import '../widgets/car_selection_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/inline_customer_creation_widget.dart';
import '../widgets/vehicle_grid_widget.dart';
import '../widgets/photo_upload_widget.dart';
import '../utils/app_theme.dart';

// Purchase source selection
enum PurchaseSource { fromCustomer, fromSupplier }

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
  final ImageUploadService _imageService = ImageUploadService();
  final WorkOrderService _workOrderService = WorkOrderService();
  final UserService _userService = UserService();
  final LoggerService _logger = logger;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected data
  Customer? _selectedCustomer;
  Car? _selectedCar;
  String _selectedPaymentMethod = AppConstants.paymentMethods[0];
  
  // Purchase source selection
  PurchaseSource _purchaseSource = PurchaseSource.fromSupplier;
  
  // State
  bool _isLoading = false;
  bool _showCustomerCreation = false;
  List<Car> _availableCars = [];
  List<Car> _customerCars = [];
  bool _loadingCars = false;
  User? _currentUser;
  
  // Photo upload
  List<XFile> _selectedPhotos = [];

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
      final response = await _carService.getAvailableCars();
      
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

  Future<void> _loadCustomerCars(String customerId) async {
    setState(() => _loadingCars = true);
    _logger.userAction('Load customer cars for purchase', data: {'customerId': customerId});

    try {
      final response = await _carService.getCarsByCustomer(customerId);
      
      if (response.success && response.data != null) {
        setState(() {
          _customerCars = response.data!;
          _selectedCar = null; // Reset selection when customer changes
        });
        _logger.info('Customer cars loaded for purchase', tag: 'Purchase', 
                    data: {'count': _customerCars.length, 'customerId': customerId});
      } else {
        setState(() => _customerCars = []);
        _logger.warning('No cars found for customer', tag: 'Purchase', 
                       data: {'customerId': customerId, 'message': response.message});
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to load customer cars', tag: 'Purchase', 
                   error: e, stackTrace: stackTrace);
      setState(() => _customerCars = []);
      _showErrorSnackBar('Failed to load customer cars: $e');
    } finally {
      setState(() => _loadingCars = false);
    }
  }

  Future<void> _submitPurchase() async {
    if (!_formKey.currentState!.validate() || _selectedCar == null || _currentUser == null) {
      _logger.warning('Purchase form validation failed', tag: 'Purchase');
      return;
    }

    // Validate customer requirement for customer purchases
    if (_purchaseSource == PurchaseSource.fromCustomer && _selectedCustomer == null) {
      _showErrorSnackBar('Please select a customer when purchasing from customer');
      return;
    }

    setState(() => _isLoading = true);
    _logger.userAction('Submit purchase', data: {
      'carId': _selectedCar!.id,
      'amount': double.tryParse(_amountController.text),
      'paymentMethod': _selectedPaymentMethod,
      'purchaseSource': _purchaseSource.toString(),
      'hasPhotos': _selectedPhotos.isNotEmpty,
      'photoCount': _selectedPhotos.length,
    });

    try {
      final request = CreatePurchaseRequest(
        customerId: _purchaseSource == PurchaseSource.fromCustomer ? _selectedCustomer?.id : null,
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
          'purchaseSource': _purchaseSource.toString(),
        });

        // Upload photos if any selected
        if (_selectedPhotos.isNotEmpty) {
          await _uploadPhotos(_selectedCar!.id);
        }

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

  Future<void> _uploadPhotos(String carId) async {
    try {
      _logger.info('Uploading photos for purchased vehicle', tag: 'Purchase', data: {
        'carId': carId,
        'photoCount': _selectedPhotos.length,
      });

      final photoTypes = ['front', 'back', 'left', 'right', 'interior', 'engine', 'dashboard', 'damage'];
      final typesToUse = _selectedPhotos.length <= photoTypes.length 
          ? photoTypes.take(_selectedPhotos.length).toList()
          : List.generate(_selectedPhotos.length, (i) => 'photo_${i + 1}');

      final response = await _imageService.uploadMultipleImages(
        imageFiles: _selectedPhotos,
        entityType: 'car',
        entityId: carId,
        photoTypes: typesToUse,
        description: 'Vehicle purchase documentation',
      );

      if (response.isSuccess) {
        _logger.info('Photos uploaded successfully', tag: 'Purchase', data: {
          'carId': carId,
          'uploadedCount': response.data?.length ?? 0,
        });
      } else {
        _logger.warning('Photo upload failed', tag: 'Purchase', data: {
          'carId': carId,
          'error': response.message,
        });
      }
    } catch (e, stackTrace) {
      _logger.error('Photo upload error', tag: 'Purchase', error: e, stackTrace: stackTrace);
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
      _purchaseSource = PurchaseSource.fromSupplier;
      _showCustomerCreation = false;
      _selectedPhotos.clear();
      _customerCars.clear();
    });
    _loadAvailableCars(); // Refresh car list
  }

  void _showSuccessDialog(Map<String, dynamic> purchaseData) {
    final invoice = purchaseData['invoice'];
    final carData = purchaseData['car'] ?? _selectedCar?.toJson();
    
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
            SizedBox(height: 8.h),
            Text('Source: ${_purchaseSource == PurchaseSource.fromCustomer ? 'Customer' : 'Supplier'}'),
            if (_selectedCustomer != null) ...[
              SizedBox(height: 8.h),
              Text('From: ${_selectedCustomer!.name}'),
            ],
            if (_selectedPhotos.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text('Photos uploaded: ${_selectedPhotos.length}'),
            ],
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Assessment Required',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Does this vehicle need service/repair before it can be sold?',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleServiceNeeded(carData, invoice);
                  },
                  icon: Icon(Icons.build, color: AppTheme.warningColor),
                  label: Text('Needs Service'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                    backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleReadyForSale(carData, invoice);
                  },
                  icon: Icon(Icons.sell, color: AppTheme.successColor),
                  label: Text('Ready to Sell'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                    backgroundColor: AppTheme.successColor.withOpacity(0.1),
                  ),
                ),
              ),
            ],
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

  Future<void> _handleServiceNeeded(Map<String, dynamic>? carData, Map<String, dynamic> invoice) async {
    try {
      _logger.info('Vehicle requires service - creating work order', tag: 'Purchase', data: {
        'carId': carData?['id'],
        'invoiceNumber': invoice['invoice_number'],
      });

      // Show mechanic selection dialog
      final selectedMechanic = await _showMechanicSelectionDialog();
      if (selectedMechanic == null) {
        _showErrorSnackBar('Service creation cancelled');
        return;
      }

      // Create work order
      final workOrderResponse = await _createWorkOrder(
        carData?['id'] ?? _selectedCar?.id ?? '',
        selectedMechanic['id'],
        'Vehicle purchased from ${_purchaseSource == PurchaseSource.fromCustomer ? 'customer' : 'supplier'} - requires service and inspection before sale',
      );

      if (workOrderResponse['success'] == true) {
        final workOrder = workOrderResponse['workOrder'];
        
        _logger.info('Work order created successfully', tag: 'Purchase', data: {
          'workOrderNumber': workOrder['work_order_number'],
          'mechanicId': selectedMechanic['id'],
        });

        // Show work order created dialog
        _showWorkOrderCreatedDialog(workOrder, selectedMechanic, invoice);
      } else {
        _showErrorSnackBar('Failed to create work order: ${workOrderResponse['message']}');
      }
    } catch (e, stackTrace) {
      _logger.error('Service creation failed', tag: 'Purchase', error: e, stackTrace: stackTrace);
      _showErrorSnackBar('Failed to create service order: $e');
    }
  }

  Future<void> _handleReadyForSale(Map<String, dynamic>? carData, Map<String, dynamic> invoice) async {
    try {
      _logger.info('Vehicle ready for sale - updating status', tag: 'Purchase', data: {
        'carId': carData?['id'],
        'invoiceNumber': invoice['invoice_number'],
      });

      // Update vehicle status to available for sale
      // Note: This would typically call an API to update car status
      // For now, just show success message and offer PDF generation
      
      _showReadyForSaleDialog(invoice);
    } catch (e, stackTrace) {
      _logger.error('Ready for sale handling failed', tag: 'Purchase', error: e, stackTrace: stackTrace);
      _showErrorSnackBar('Failed to process vehicle: $e');
    }
  }

  Future<Map<String, dynamic>?> _showMechanicSelectionDialog() async {
    try {
      // Get all mechanics from the system
      final mechanics = await _getMechanics();
      if (mechanics.isEmpty) {
        _showErrorSnackBar('No mechanics available. Please contact admin.');
        return null;
      }

      return await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Assign Mechanic'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select a mechanic to handle this vehicle service:'),
              SizedBox(height: 16.h),
              ...mechanics.map((mechanic) => ListTile(
                leading: CircleAvatar(
                  child: Text(mechanic['name'][0].toUpperCase()),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                title: Text(mechanic['name']),
                subtitle: Text('Role: ${mechanic['role']}'),
                onTap: () => Navigator.of(context).pop(mechanic),
              )).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      _logger.error('Mechanic selection failed', tag: 'Purchase', error: e);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getMechanics() async {
    try {
      final mechanics = await _userService.getMechanics();
      return mechanics.map((mechanic) => {
        'id': mechanic.id,
        'name': mechanic.name,
        'role': mechanic.role,
        'email': mechanic.email,
      }).toList();
    } catch (e) {
      _logger.error('Failed to get mechanics', tag: 'Purchase', error: e);
      return [];
    }
  }

  Future<Map<String, dynamic>> _createWorkOrder(String carId, String mechanicId, String description) async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      return await _workOrderService.createWorkOrder(
        carId: carId,
        mechanicId: mechanicId,
        description: description,
        laborCost: 0.0, // Will be filled by mechanic
        notes: 'Created automatically from vehicle purchase',
      );
    } catch (e) {
      return {'success': false, 'message': 'Failed to create work order: $e'};
    }
  }

  void _showWorkOrderCreatedDialog(Map<String, dynamic> workOrder, Map<String, dynamic> mechanic, Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.build_circle, color: AppTheme.warningColor, size: 24.sp),
            SizedBox(width: 8.w),
            Text('Work Order Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Work Order: ${workOrder['work_order_number']}'),
            SizedBox(height: 8.h),
            Text('Assigned to: ${mechanic['name']}'),
            SizedBox(height: 8.h),
            Text('Status: Pending'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'The mechanic will receive this work order and can start service. You can generate the purchase invoice PDF for your records.',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateAndSendPDF(invoice);
            },
            child: Text('Generate PDF & Send WhatsApp'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showReadyForSaleDialog(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sell, color: AppTheme.successColor, size: 24.sp),
            SizedBox(width: 8.w),
            Text('Ready for Sale'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle is now available in sales inventory.'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'The vehicle has been marked as ready for sale and can be found in the sales inventory. Generate invoice PDF for your records.',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateAndSendPDF(invoice);
            },
            child: Text('Generate PDF & Send WhatsApp'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSendPDF(Map<String, dynamic> invoice) async {
    try {
      setState(() => _isLoading = true);
      
      _logger.info('Generating PDF for invoice', tag: 'Purchase', data: {
        'invoiceNumber': invoice['invoice_number'],
      });

      // Show PDF generation dialog
      _showPDFGenerationDialog(invoice);
      
    } catch (e, stackTrace) {
      _logger.error('PDF generation failed', tag: 'Purchase', error: e, stackTrace: stackTrace);
      _showErrorSnackBar('Failed to generate PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPDFGenerationDialog(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor, size: 24.sp),
            SizedBox(width: 8.w),
            Text('Generate PDF Invoice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text('Generating PDF invoice...'),
            SizedBox(height: 8.h),
            Text('Invoice: ${invoice['invoice_number']}', 
                 style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
          ],
        ),
      ),
    );

    // Simulate PDF generation
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pop();
      _showPDFGeneratedDialog(invoice);
    });
  }

  void _showPDFGeneratedDialog(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 24.sp),
            SizedBox(width: 8.w),
            Text('PDF Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PDF invoice has been generated successfully!'),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Open WhatsApp with pre-filled message
                      _openWhatsApp(invoice);
                    },
                    icon: Icon(Icons.send),
                    label: Text('Send WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF25D366), // WhatsApp green
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Download PDF functionality
                      _downloadPDF(invoice);
                    },
                    icon: Icon(Icons.download),
                    label: Text('Download'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Done'),
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(Map<String, dynamic> invoice) {
    try {
      final customerPhone = _selectedCustomer?.phoneNumber ?? '';
      final message = 'Halo! Invoice pembelian kendaraan Anda telah siap.\n\n'
                     'No. Invoice: ${invoice['invoice_number']}\n'
                     'Total: Rp ${_formatCurrency(invoice['total_amount'])}\n\n'
                     'Terima kasih telah menjual kendaraan kepada kami.';
      
      _logger.info('Opening WhatsApp', tag: 'Purchase', data: {
        'phone': customerPhone,
        'invoiceNumber': invoice['invoice_number'],
      });

      // In a real app, this would open WhatsApp
      _showErrorSnackBar('WhatsApp integration coming soon! Phone: $customerPhone');
      
      Navigator.of(context).pop();
    } catch (e) {
      _logger.error('WhatsApp opening failed', tag: 'Purchase', error: e);
      _showErrorSnackBar('Failed to open WhatsApp: $e');
    }
  }

  void _downloadPDF(Map<String, dynamic> invoice) {
    try {
      _logger.info('Downloading PDF', tag: 'Purchase', data: {
        'invoiceNumber': invoice['invoice_number'],
      });

      // In a real app, this would trigger PDF download
      _showErrorSnackBar('PDF download functionality coming soon!');
      
      Navigator.of(context).pop();
    } catch (e) {
      _logger.error('PDF download failed', tag: 'Purchase', error: e);
      _showErrorSnackBar('Failed to download PDF: $e');
    }
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

                  // Source Selection
                  _buildSourceSelection(),
                  SizedBox(height: 20.h),

                  // Customer Section (for customer purchases)
                  if (_purchaseSource == PurchaseSource.fromCustomer)
                    _buildCustomerSection(),

                  // Vehicle Selection
                  _buildVehicleSelection(),
                  SizedBox(height: 20.h),

                  // Photo Upload Section
                  _buildPhotoUploadSection(),
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
                'Purchase Vehicle',
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
            _purchaseSource == PurchaseSource.fromCustomer
                ? 'Buy vehicle from customer and automatically generate purchase invoice'
                : 'Purchase vehicle from supplier for showroom inventory',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.source, color: AppTheme.primaryColor, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Purchase Source',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<PurchaseSource>(
                    title: Text('From Supplier'),
                    subtitle: Text('New inventory from suppliers'),
                    value: PurchaseSource.fromSupplier,
                    groupValue: _purchaseSource,
                    onChanged: (value) {
                      setState(() {
                        _purchaseSource = value!;
                        _selectedCustomer = null;
                        _selectedCar = null;
                        _customerCars.clear();
                        _showCustomerCreation = false;
                      });
                      _loadAvailableCars();
                      _logger.userAction('Purchase source changed', data: {'source': value.toString()});
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<PurchaseSource>(
                    title: Text('From Customer'),
                    subtitle: Text('Buy from customer vehicle'),
                    value: PurchaseSource.fromCustomer,
                    groupValue: _purchaseSource,
                    onChanged: (value) {
                      setState(() {
                        _purchaseSource = value!;
                        _selectedCustomer = null;
                        _selectedCar = null;
                        _customerCars.clear();
                        _showCustomerCreation = false;
                      });
                      _logger.userAction('Purchase source changed', data: {'source': value.toString()});
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

  Widget _buildCustomerSection() {
    return Column(
      children: [
        // Customer Selection or Creation
        if (!_showCustomerCreation)
          _buildCustomerSelection()
        else
          _buildCustomerCreation(),
        
        SizedBox(height: 20.h),
      ],
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
                  _purchaseSource == PurchaseSource.fromCustomer ? 'Select Customer' : 'Customer (Optional)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                if (_purchaseSource == PurchaseSource.fromCustomer)
                  TextButton.icon(
                    onPressed: () => setState(() => _showCustomerCreation = true),
                    icon: Icon(Icons.add, size: 16.sp),
                    label: Text('New Customer'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            CustomerSelectionWidget(
              selectedCustomer: _selectedCustomer,
              onCustomerSelected: (customer) {
                setState(() => _selectedCustomer = customer);
                if (_purchaseSource == PurchaseSource.fromCustomer && customer != null) {
                  _loadCustomerCars(customer.id);
                }
                _logger.userAction('Customer selected for purchase', data: {
                  'customerId': customer?.id,
                  'customerName': customer?.name,
                  'purchaseSource': _purchaseSource.toString(),
                });
              },
              hintText: _purchaseSource == PurchaseSource.fromCustomer 
                  ? 'Select customer selling the vehicle'
                  : 'Select customer selling the vehicle (optional)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCreation() {
    return InlineCustomerCreationWidget(
      onCustomerCreated: (customer) {
        setState(() {
          _selectedCustomer = customer;
          _showCustomerCreation = false;
        });
        if (_purchaseSource == PurchaseSource.fromCustomer) {
          _loadCustomerCars(customer.id);
        }
        _logger.userAction('New customer created for purchase', data: {
          'customerId': customer.id,
          'customerName': customer.name,
        });
      },
      onCancel: () => setState(() => _showCustomerCreation = false),
    );
  }

  Widget _buildVehicleSelection() {
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
                  _purchaseSource == PurchaseSource.fromCustomer 
                      ? 'Customer Vehicles' 
                      : 'Available Vehicles',
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
            
            // Show appropriate vehicle grid based on source
            if (_purchaseSource == PurchaseSource.fromCustomer) ...[
              if (_selectedCustomer == null)
                _buildNoCustomerSelectedState()
              else
                VehicleGridWidget(
                  vehicles: _customerCars,
                  selectedVehicle: _selectedCar,
                  onVehicleSelected: (car) {
                    setState(() => _selectedCar = car);
                    _logger.userAction('Customer vehicle selected', data: {
                      'carId': car.id,
                      'customerId': _selectedCustomer?.id,
                    });
                  },
                  showOwnershipBadge: true,
                  ownershipLabel: 'Customer',
                ),
            ] else ...[
              VehicleGridWidget(
                vehicles: _availableCars,
                selectedVehicle: _selectedCar,
                onVehicleSelected: (car) {
                  setState(() => _selectedCar = car);
                  _logger.userAction('Supplier vehicle selected', data: {
                    'carId': car.id,
                  });
                },
                showOwnershipBadge: true,
                ownershipLabel: 'Supplier',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoCustomerSelectedState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_search,
            size: 48.sp,
            color: Colors.blue[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Select a Customer First',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please select a customer above to see their vehicles available for purchase',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.blue[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return PhotoUploadWidget(
      onPhotosSelected: (photos) {
        setState(() => _selectedPhotos = photos);
        _logger.userAction('Photos selected for purchase', data: {
          'photoCount': photos.length,
          'fileNames': photos.map((p) => p.name).toList(),
        });
      },
      allowMultiple: true,
      title: 'Vehicle Documentation',
      subtitle: 'Upload photos of the vehicle being purchased (optional)',
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
    final isFormValid = _selectedCar != null && 
                       _amountController.text.isNotEmpty &&
                       (_purchaseSource == PurchaseSource.fromSupplier || _selectedCustomer != null);
    
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