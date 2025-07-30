class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Pagination? pagination;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.pagination,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null 
          ? fromJsonT(json['data']) 
          : json['data'],
      pagination: json['pagination'] != null 
          ? Pagination.fromJson(json['pagination']) 
          : null,
    );
  }

  bool get isSuccess => success;
  bool get hasData => data != null;
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['total_pages'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'total_pages': totalPages,
    };
  }

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;
}

class CreateSaleRequest {
  final String customerId;
  final String carId;
  final double amount;
  final double discountAmount;
  final String paymentMethod;
  final String? notes;
  final String createdBy;

  CreateSaleRequest({
    required this.customerId,
    required this.carId,
    required this.amount,
    required this.discountAmount,
    required this.paymentMethod,
    this.notes,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'car_id': carId,
      'amount': amount,
      'discount_amount': discountAmount,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}

class CreatePurchaseRequest {
  final String customerId;
  final String carId;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final String createdBy;

  CreatePurchaseRequest({
    required this.customerId,
    required this.carId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'car_id': carId,
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_by': createdBy,
    };
  }
}