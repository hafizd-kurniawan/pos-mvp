class Car {
  final String id;
  final String licensePlate;
  final String brand;
  final String model;
  final int year;
  final String color;
  final String? vin;
  final String? engineNumber;
  final String fuelType;
  final String transmission;
  final int mileage;
  final String status; // available, in_repair, sold, reserved
  final double? purchasePrice;
  final double? sellingPrice;
  final String? condition;
  final String? notes;
  final String? primaryPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Car({
    required this.id,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    this.vin,
    this.engineNumber,
    required this.fuelType,
    required this.transmission,
    required this.mileage,
    required this.status,
    this.purchasePrice,
    this.sellingPrice,
    this.condition,
    this.notes,
    this.primaryPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'],
      licensePlate: json['license_plate'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
      color: json['color'],
      vin: json['vin'],
      engineNumber: json['engine_number'],
      fuelType: json['fuel_type'],
      transmission: json['transmission'],
      mileage: json['mileage'],
      status: json['status'],
      purchasePrice: json['purchase_price']?.toDouble(),
      sellingPrice: json['selling_price']?.toDouble(),
      condition: json['condition'],
      notes: json['notes'],
      primaryPhotoUrl: json['primary_photo_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'license_plate': licensePlate,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'vin': vin,
      'engine_number': engineNumber,
      'fuel_type': fuelType,
      'transmission': transmission,
      'mileage': mileage,
      'status': status,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'condition': condition,
      'notes': notes,
      'primary_photo_url': primaryPhotoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName => '$brand $model $year';
  
  String get statusDisplayName {
    switch (status) {
      case 'available':
        return 'Ready to Sell';
      case 'in_repair':
        return 'In Workshop';
      case 'sold':
        return 'Sold';
      case 'reserved':
        return 'Reserved';
      default:
        return status;
    }
  }

  bool get isAvailableForSale => status == 'available';

  @override
  String toString() {
    return 'Car(id: $id, plate: $licensePlate, name: $displayName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Car && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}