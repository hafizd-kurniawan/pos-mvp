import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/inventory_car_card.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final CarService _carService = CarService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Car> _cars = [];
  List<Car> _filteredCars = [];
  List<String> _brands = [];
  bool _isLoading = false;
  bool _isSearching = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  
  // Filter parameters - matching sales screen
  String? _selectedBrandFilter;
  String? _selectedFuelTypeFilter;
  String? _selectedTransmissionFilter;

  @override
  void initState() {
    super.initState();
    _loadCars();
    _loadBrands();
    _setupFilterListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupFilterListener() {
    _searchController.addListener(() {
      _filterVehicles();
    });
  }

  Future<void> _loadCars({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _cars.clear();
        _hasMoreData = true;
      });
    }

    setState(() => _isLoading = true);

    try {
      final response = await _carService.getAvailableCars(
        page: _currentPage,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          if (isRefresh) {
            _cars = response.data!;
            _filteredCars = response.data!;
          } else {
            _cars.addAll(response.data!);
            _filteredCars = _cars;
          }
          _hasMoreData = response.pagination?.hasNext ?? false;
          if (_hasMoreData) _currentPage++;
        });
        _filterVehicles(); // Apply current filters
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error loading cars: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBrands() async {
    try {
      final response = await _carService.getCarBrands();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _brands = response.data!;
        });
      }
    } catch (e) {
      // Silently handle error for brands loading
    }
  }

  void _filterVehicles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCars = _cars.where((car) {
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
      _searchController.clear();
      _selectedBrandFilter = null;
      _selectedFuelTypeFilter = null;
      _selectedTransmissionFilter = null;
      _filteredCars = _cars;
    });
  }

  Future<void> _showCarDetails(Car car) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.directions_car_rounded,
                size: 20.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                car.displayName,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (car.imageUrl != null && car.imageUrl!.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 200.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    image: DecorationImage(
                      image: NetworkImage(car.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.directions_car_outlined,
                    size: 48.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              SizedBox(height: 16.h),
              _buildDetailRow('Brand', car.brand),
              _buildDetailRow('Model', car.model),
              _buildDetailRow('Year', car.year.toString()),
              _buildDetailRow('License Plate', car.licensePlate),
              _buildDetailRow('Color', car.color),
              _buildDetailRow('Fuel Type', car.fuelType),
              _buildDetailRow('Transmission', car.transmission),
              if (car.sellingPrice != null)
                _buildDetailRow('Selling Price', 'Rp ${car.sellingPrice!.toStringAsFixed(0)}'),
              if (car.condition.isNotEmpty)
                _buildDetailRow('Condition', car.condition),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getUniqueBrands() {
    return _cars
        .map((car) => car.brand)
        .where((brand) => brand.isNotEmpty)
        .toSet()
        .toList()
        ..sort();
  }

  List<String> _getUniqueFuelTypes() {
    return _cars
        .map((car) => car.fuelType)
        .where((fuel) => fuel.isNotEmpty)
        .toSet()
        .toList()
        ..sort();
  }

  List<String> _getUniqueTransmissions() {
    return _cars
        .map((car) => car.transmission)
        .where((trans) => trans.isNotEmpty)
        .toSet()
        .toList()
        ..sort();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedBrandFilter != null) count++;
    if (_selectedFuelTypeFilter != null) count++;
    if (_selectedTransmissionFilter != null) count++;
    if (_searchController.text.isNotEmpty) count++;
    return count;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }

  Widget _buildVehicleFilters() {
    return Container(
      margin: EdgeInsets.all(24.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 20.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  'Search & Filter Vehicles',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
              if (_activeFilterCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$_activeFilterCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20.h),
          
          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by brand, model, license plate, color...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14.sp,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20.sp,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          size: 20.sp,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 16.h,
                ),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Filter dropdowns - matching sales screen
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedBrandFilter,
                    decoration: InputDecoration(
                      labelText: 'Brand',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      border: InputBorder.none,
                      labelStyle: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'All Brands',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ..._getUniqueBrands()
                          .map((brand) => DropdownMenuItem(
                                value: brand,
                                child: Text(
                                  brand,
                                  style: TextStyle(fontSize: 14.sp),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ))
                          .toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedBrandFilter = value;
                      });
                      _filterVehicles();
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedFuelTypeFilter,
                    decoration: InputDecoration(
                      labelText: 'Fuel Type',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      border: InputBorder.none,
                      labelStyle: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'All Fuel Types',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ..._getUniqueFuelTypes()
                          .map((fuel) => DropdownMenuItem(
                                value: fuel,
                                child: Text(
                                  fuel,
                                  style: TextStyle(fontSize: 14.sp),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ))
                          .toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFuelTypeFilter = value;
                      });
                      _filterVehicles();
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedTransmissionFilter,
                    decoration: InputDecoration(
                      labelText: 'Transmission',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      border: InputBorder.none,
                      labelStyle: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(
                          'All Transmissions',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ..._getUniqueTransmissions()
                          .map((trans) => DropdownMenuItem(
                                value: trans,
                                child: Text(
                                  trans,
                                  style: TextStyle(fontSize: 14.sp),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ))
                          .toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTransmissionFilter = value;
                      });
                      _filterVehicles();
                    },
                  ),
                ),
              ),
            ],
          ),
          
          // Clear filters button
          if (_activeFilterCount > 0) ...[
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _clearFilters,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                  ),
                  icon: Icon(Icons.clear_all_rounded, size: 16.sp),
                  label: Text(
                    'Clear All Filters',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 20.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Vehicle Inventory',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Manage vehicle stock',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: Container(
          margin: EdgeInsets.only(left: 16.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              onPressed: () => _loadCars(isRefresh: true),
            ),
          ),
        ],
      ),
      
      body: LoadingOverlay(
        isLoading: _isLoading && _cars.isEmpty,
        child: Column(
          children: [
            // Modern search and filter section
            _buildVehicleFilters(),
            
            // Vehicle count with modern design
            if (_filteredCars.isNotEmpty)
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.directions_car_rounded,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '${_filteredCars.length} vehicles available',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 16.h),
            
            // Vehicle grid with 4 columns
            Expanded(
              child: _filteredCars.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 40.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'No vehicles found',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Try adjusting your search filters\nor contact admin to add vehicles',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // Fixed 4 columns as requested
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _filteredCars.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredCars.length) {
                          // Load more indicator
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40.w,
                                  height: 40.h,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 24.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : () => _loadCars(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 16.w,
                                          height: 16.h,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Load More',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          );
                        }

                        final car = _filteredCars[index];
                        return InventoryCarCard(
                          car: car,
                          onTap: () => _showCarDetails(car),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}