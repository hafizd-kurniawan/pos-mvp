class WorkOrder {
  final String id;
  final String workOrderNumber;
  final String carId;
  final String? mechanicId;
  final String assignedBy;
  final String description;
  final double laborCost;
  final double partsCost;
  final double totalCost;
  final String status; // pending, in_progress, completed, cancelled
  final int progress; // 0-100 percentage
  final DateTime? startDate;
  final DateTime? completedDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkOrder({
    required this.id,
    required this.workOrderNumber,
    required this.carId,
    this.mechanicId,
    required this.assignedBy,
    required this.description,
    required this.laborCost,
    required this.partsCost,
    required this.totalCost,
    required this.status,
    required this.progress,
    this.startDate,
    this.completedDate,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkOrder.fromJson(Map<String, dynamic> json) {
    return WorkOrder(
      id: json['id']?.toString() ?? '',
      workOrderNumber: json['work_order_number']?.toString() ?? '',
      carId: json['car_id']?.toString() ?? '',
      mechanicId: json['mechanic_id']?.toString(),
      assignedBy: json['assigned_by']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      laborCost: (json['labor_cost']?.toDouble()) ?? 0.0,
      partsCost: (json['parts_cost']?.toDouble()) ?? 0.0,
      totalCost: (json['total_cost']?.toDouble()) ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      progress: json['progress']?.toInt() ?? 0,
      startDate: json['start_date'] != null 
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      completedDate: json['completed_date'] != null 
          ? DateTime.tryParse(json['completed_date'].toString())
          : null,
      notes: json['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'work_order_number': workOrderNumber,
      'car_id': carId,
      'mechanic_id': mechanicId,
      'assigned_by': assignedBy,
      'description': description,
      'labor_cost': laborCost,
      'parts_cost': partsCost,
      'total_cost': totalCost,
      'status': status,
      'progress': progress,
      'start_date': startDate?.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  @override
  String toString() {
    return 'WorkOrder(id: $id, workOrderNumber: $workOrderNumber, status: $status, progress: $progress%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkOrder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class WorkOrderItem {
  final String id;
  final String workOrderId;
  final String sparepartId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime usedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkOrderItem({
    required this.id,
    required this.workOrderId,
    required this.sparepartId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.usedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkOrderItem.fromJson(Map<String, dynamic> json) {
    return WorkOrderItem(
      id: json['id']?.toString() ?? '',
      workOrderId: json['work_order_id']?.toString() ?? '',
      sparepartId: json['sparepart_id']?.toString() ?? '',
      quantity: json['quantity']?.toInt() ?? 0,
      unitPrice: (json['unit_price']?.toDouble()) ?? 0.0,
      totalPrice: (json['total_price']?.toDouble()) ?? 0.0,
      usedDate: DateTime.tryParse(json['used_date']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'work_order_id': workOrderId,
      'sparepart_id': sparepartId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'used_date': usedDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'WorkOrderItem(id: $id, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkOrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Sparepart {
  final String id;
  final String partNumber;
  final String name;
  final String description;
  final String brand;
  final String category;
  final int stock;
  final int minStock;
  final double costPrice;
  final double salePrice;
  final double markupPercent;
  final String location;
  final String barcode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sparepart({
    required this.id,
    required this.partNumber,
    required this.name,
    required this.description,
    required this.brand,
    required this.category,
    required this.stock,
    required this.minStock,
    required this.costPrice,
    required this.salePrice,
    required this.markupPercent,
    required this.location,
    required this.barcode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sparepart.fromJson(Map<String, dynamic> json) {
    return Sparepart(
      id: json['id']?.toString() ?? '',
      partNumber: json['part_number']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      stock: json['stock']?.toInt() ?? 0,
      minStock: json['min_stock']?.toInt() ?? 0,
      costPrice: (json['cost_price']?.toDouble()) ?? 0.0,
      salePrice: (json['sale_price']?.toDouble()) ?? 0.0,
      markupPercent: (json['markup_percent']?.toDouble()) ?? 0.0,
      location: json['location']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'part_number': partNumber,
      'name': name,
      'description': description,
      'brand': brand,
      'category': category,
      'stock': stock,
      'min_stock': minStock,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'markup_percent': markupPercent,
      'location': location,
      'barcode': barcode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isLowStock => stock <= minStock;

  @override
  String toString() {
    return 'Sparepart(id: $id, name: $name, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sparepart && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}