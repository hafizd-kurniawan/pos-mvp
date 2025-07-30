import 'customer.dart';
import 'car.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String invoiceType; // purchase, sale
  final String? customerId;
  final String? carId;
  final double amount;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod; // cash, transfer, credit
  final String status; // draft, paid, pending, cancelled
  final String? paymentProof;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related objects (populated by API joins)
  final Customer? customer;
  final Car? car;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceType,
    this.customerId,
    this.carId,
    required this.amount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.paymentProof,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.car,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      invoiceType: json['invoice_type']?.toString() ?? '',
      customerId: json['customer_id']?.toString(),
      carId: json['car_id']?.toString(),
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      discountAmount: json['discount_amount'] != null ? double.tryParse(json['discount_amount'].toString()) ?? 0.0 : 0.0,
      totalAmount: json['total_amount'] != null ? double.tryParse(json['total_amount'].toString()) ?? 0.0 : 0.0,
      paymentMethod: json['payment_method']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentProof: json['payment_proof']?.toString(),
      notes: json['notes']?.toString(),
      createdBy: json['created_by']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      car: json['car'] != null ? Car.fromJson(json['car']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'invoice_type': invoiceType,
      'customer_id': customerId,
      'car_id': carId,
      'amount': amount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'status': status,
      'payment_proof': paymentProof,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get typeDisplayName {
    switch (invoiceType) {
      case 'purchase':
        return 'Purchase';
      case 'sale':
        return 'Sale';
      default:
        return invoiceType;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending Payment';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case 'cash':
        return 'Cash';
      case 'transfer':
        return 'Bank Transfer';
      case 'credit':
        return 'Credit';
      default:
        return paymentMethod;
    }
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isDraft => status == 'draft';
  bool get isCancelled => status == 'cancelled';

  @override
  String toString() {
    return 'Invoice(id: $id, number: $invoiceNumber, type: $invoiceType, total: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}