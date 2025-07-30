import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      appBar: AppBar(
        title: const Text('Car Inventory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCars(isRefresh: true),
          ),
        ],
      ),
      
      body: LoadingOverlay(
        isLoading: _isLoading && _cars.isEmpty,
        child: Column(
          children: [
            // Search and filter section
            Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by brand, model, license plate...',
                            prefixIcon: Icon(Icons.search, size: 20.sp),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, size: 20.sp),
                                    onPressed: () {
                                      _searchController.clear();
                                      _loadCars(isRefresh: true);
                                    },
                                  )
                                : null,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _loadCars(isRefresh: true),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Badge(
                        isLabelVisible: _activeFilterCount > 0,
                        label: Text(_activeFilterCount.toString()),
                        child: IconButton.filled(
                          onPressed: _showFilterDialog,
                          icon: Icon(Icons.tune, size: 20.sp),
                        ),
                      ),
                    ],
                  ),
                  
                  // Active filters display
                  if (_activeFilterCount > 0) ...[
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Text(
                          'Filters applied:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Wrap(
                            spacing: 4.w,
                            children: [
                              if (_selectedBrand != null)
                                Chip(
                                  label: Text(_selectedBrand!),
                                  deleteIcon: Icon(Icons.close, size: 16.sp),
                                  onDeleted: () {
                                    setState(() => _selectedBrand = null);
                                    _searchCars();
                                  },
                                ),
                              if (_selectedModel != null)
                                Chip(
                                  label: Text(_selectedModel!),
                                  deleteIcon: Icon(Icons.close, size: 16.sp),
                                  onDeleted: () {
                                    setState(() => _selectedModel = null);
                                    _searchCars();
                                  },
                                ),
                              if (_yearFrom != null || _yearTo != null)
                                Chip(
                                  label: Text('${_yearFrom ?? ''}-${_yearTo ?? ''}'),
                                  deleteIcon: Icon(Icons.close, size: 16.sp),
                                  onDeleted: () {
                                    setState(() {
                                      _yearFrom = null;
                                      _yearTo = null;
                                    });
                                    _searchCars();
                                  },
                                ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: Icon(Icons.clear_all, size: 16.sp),
                          label: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Car count
            if (_cars.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                color: Colors.grey.shade50,
                child: Text(
                  '${_cars.length} vehicles available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            
            // Car grid
            Expanded(
              child: _cars.isEmpty && !_isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 64.sp,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No vehicles found',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Try adjusting your search filters',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(16.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: ResponsiveBreakpoints.of(context).isTablet ? 3 : 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _cars.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _cars.length) {
                          // Load more indicator
                          return Center(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _loadCars(),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: const CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Load More'),
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