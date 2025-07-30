import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:go_router/go_router.dart';
import '../models/car.dart';
import '../services/car_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/inventory_car_card.dart';
import '../widgets/placeholder_widgets.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final CarService _carService = CarService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Car> _cars = [];
  List<String> _brands = [];
  bool _isLoading = false;
  bool _isSearching = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  
  // Filter parameters
  String? _selectedBrand;
  String? _selectedModel;
  int? _yearFrom;
  int? _yearTo;
  double? _priceFrom;
  double? _priceTo;
  String? _fuelType;
  String? _transmission;

  @override
  void initState() {
    super.initState();
    _loadCars();
    _loadBrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          } else {
            _cars.addAll(response.data!);
          }
          _hasMoreData = response.pagination?.hasNext ?? false;
          if (_hasMoreData) _currentPage++;
        });
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

  Future<void> _searchCars() async {
    setState(() => _isSearching = true);
    
    try {
      final response = await _carService.searchCars(
        brand: _selectedBrand,
        model: _selectedModel,
        yearFrom: _yearFrom,
        yearTo: _yearTo,
        priceFrom: _priceFrom,
        priceTo: _priceTo,
        fuelType: _fuelType,
        transmission: _transmission,
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          _cars = response.data!;
          _hasMoreData = response.pagination?.hasNext ?? false;
          _currentPage = response.pagination?.page ?? 1;
          if (_hasMoreData) _currentPage++;
        });
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error searching cars: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CarFilterDialog(
        brands: _brands,
        selectedBrand: _selectedBrand,
        selectedModel: _selectedModel,
        yearFrom: _yearFrom,
        yearTo: _yearTo,
        priceFrom: _priceFrom,
        priceTo: _priceTo,
        fuelType: _fuelType,
        transmission: _transmission,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedBrand = result['brand'];
        _selectedModel = result['model'];
        _yearFrom = result['yearFrom'];
        _yearTo = result['yearTo'];
        _priceFrom = result['priceFrom'];
        _priceTo = result['priceTo'];
        _fuelType = result['fuelType'];
        _transmission = result['transmission'];
      });
      
      await _searchCars();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedBrand = null;
      _selectedModel = null;
      _yearFrom = null;
      _yearTo = null;
      _priceFrom = null;
      _priceTo = null;
      _fuelType = null;
      _transmission = null;
      _searchController.clear();
    });
    _loadCars(isRefresh: true);
  }

  Future<void> _showCarDetails(Car car) async {
    await showDialog(
      context: context,
      builder: (context) => CarDetailsDialog(car: car),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedBrand != null) count++;
    if (_selectedModel != null) count++;
    if (_yearFrom != null) count++;
    if (_yearTo != null) count++;
    if (_priceFrom != null) count++;
    if (_priceTo != null) count++;
    if (_fuelType != null) count++;
    if (_transmission != null) count++;
    return count;
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
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
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
                Icons.directions_car_rounded,
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
            Container(
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
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
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
                                        _loadCars(isRefresh: true);
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
                            onSubmitted: (_) => _loadCars(isRefresh: true),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _showFilterDialog,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.all(16.w),
                          ),
                          icon: Icon(Icons.tune_rounded, size: 20.sp),
                        ),
                      ),
                    ],
                  ),
                  
                  // Active filters display
                  if (_activeFilterCount > 0) ...[
                    SizedBox(height: 20.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                size: 16.sp,
                                color: AppTheme.primaryColor,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Active Filters',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _clearFilters,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                ),
                                icon: Icon(Icons.clear_all_rounded, size: 14.sp),
                                label: Text(
                                  'Clear All',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              if (_selectedBrand != null)
                                _FilterChip(
                                  label: 'Brand: $_selectedBrand',
                                  onDeleted: () {
                                    setState(() => _selectedBrand = null);
                                    _searchCars();
                                  },
                                ),
                              if (_selectedModel != null)
                                _FilterChip(
                                  label: 'Model: $_selectedModel',
                                  onDeleted: () {
                                    setState(() => _selectedModel = null);
                                    _searchCars();
                                  },
                                ),
                              if (_yearFrom != null || _yearTo != null)
                                _FilterChip(
                                  label: 'Year: ${_yearFrom ?? ''}-${_yearTo ?? ''}',
                                  onDeleted: () {
                                    setState(() {
                                      _yearFrom = null;
                                      _yearTo = null;
                                    });
                                    _searchCars();
                                  },
                                ),
                              if (_fuelType != null)
                                _FilterChip(
                                  label: 'Fuel: $_fuelType',
                                  onDeleted: () {
                                    setState(() => _fuelType = null);
                                    _searchCars();
                                  },
                                ),
                              if (_transmission != null)
                                _FilterChip(
                                  label: 'Trans: $_transmission',
                                  onDeleted: () {
                                    setState(() => _transmission = null);
                                    _searchCars();
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Vehicle count with modern design
            if (_cars.isNotEmpty)
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
                      '${_cars.length} vehicles available',
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
              child: _cars.isEmpty && !_isLoading
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
                              Icons.directions_car_outlined,
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
                      itemCount: _cars.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _cars.length) {
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

                        final car = _cars[index];
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

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _FilterChip({
    required this.label,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: onDeleted,
            child: Container(
              width: 16.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 10.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}