import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/work_order.dart';
import 'auth_service.dart';

class WorkOrderService {
  final AuthService _authService = AuthService();

  // Get work orders assigned to current user (mechanic)
  Future<Map<String, dynamic>> getMyWorkOrders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/work-orders/mechanic/${user.id}?page=$page&limit=$limit'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final workOrdersData = data['data'] as List;
        final workOrders = workOrdersData.map((item) => WorkOrder.fromJson(item)).toList();

        return {
          'success': true,
          'message': 'Work orders retrieved successfully',
          'workOrders': workOrders,
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve work orders',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get all work orders (for admin/manager)
  Future<Map<String, dynamic>> getAllWorkOrders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/work-orders?page=$page&limit=$limit'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final workOrdersData = data['data'] as List;
        final workOrders = workOrdersData.map((item) => WorkOrder.fromJson(item)).toList();

        return {
          'success': true,
          'message': 'Work orders retrieved successfully',
          'workOrders': workOrders,
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve work orders',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get work orders by status
  Future<Map<String, dynamic>> getWorkOrdersByStatus(
    String status, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/work-orders/status/$status?page=$page&limit=$limit'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final workOrdersData = data['data'] as List;
        final workOrders = workOrdersData.map((item) => WorkOrder.fromJson(item)).toList();

        return {
          'success': true,
          'message': 'Work orders retrieved successfully',
          'workOrders': workOrders,
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve work orders',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get specific work order by ID
  Future<Map<String, dynamic>> getWorkOrder(String workOrderId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/work-orders/$workOrderId'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final workOrder = WorkOrder.fromJson(data['data']);

        return {
          'success': true,
          'message': 'Work order retrieved successfully',
          'workOrder': workOrder,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Work order not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update work order progress
  Future<Map<String, dynamic>> updateProgress(String workOrderId, int progress) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/work-orders/$workOrderId/progress'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'progress': progress,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Progress updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update progress',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Add parts to work order
  Future<Map<String, dynamic>> addWorkOrderItem(
    String workOrderId,
    String sparepartId,
    int quantity,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/work-orders/$workOrderId/items'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'sparepart_id': sparepartId,
          'quantity': quantity,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Part added to work order successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to add part to work order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get work order items
  Future<Map<String, dynamic>> getWorkOrderItems(String workOrderId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/work-orders/$workOrderId/items'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final itemsData = data['data'] as List;
        final items = itemsData.map((item) => WorkOrderItem.fromJson(item)).toList();

        return {
          'success': true,
          'message': 'Work order items retrieved successfully',
          'items': items,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve work order items',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Create work order (for admin/manager)
  Future<Map<String, dynamic>> createWorkOrder({
    required String carId,
    String? mechanicId,
    required String description,
    required double laborCost,
    String notes = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/work-orders'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode({
          'car_id': carId,
          'mechanic_id': mechanicId,
          'description': description,
          'labor_cost': laborCost,
          'notes': notes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final workOrder = WorkOrder.fromJson(data['data']);

        return {
          'success': true,
          'message': 'Work order created successfully',
          'workOrder': workOrder,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create work order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update work order
  Future<Map<String, dynamic>> updateWorkOrder(WorkOrder workOrder) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/work-orders/${workOrder.id}'),
        headers: _authService.getAuthHeaders(),
        body: jsonEncode(workOrder.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final updatedWorkOrder = WorkOrder.fromJson(data['data']);

        return {
          'success': true,
          'message': 'Work order updated successfully',
          'workOrder': updatedWorkOrder,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update work order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get spare parts (for adding to work orders)
  Future<Map<String, dynamic>> getSpareparts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      String url = '${AppConstants.baseUrl}${AppConstants.sparepartsEndpoint}?page=$page&limit=$limit';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final sparepartsData = data['data'] as List;
        final spareparts = sparepartsData.map((item) => Sparepart.fromJson(item)).toList();

        return {
          'success': true,
          'message': 'Spare parts retrieved successfully',
          'spareparts': spareparts,
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to retrieve spare parts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Scan barcode to find spare part
  Future<Map<String, dynamic>> scanBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.sparepartsEndpoint}/barcode?barcode=$barcode'),
        headers: _authService.getAuthHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final sparepart = Sparepart.fromJson(data['data']);

        return {
          'success': true,
          'message': 'Spare part found',
          'sparepart': sparepart,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Spare part not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}