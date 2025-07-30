class Photo {
  final String id;
  final String entityType; // car, work_order, etc.
  final String entityId;
  final String? photoType; // front, back, interior, engine, damage, before, after
  final String filename;
  final String filePath;
  final String? caption;
  final bool isPrimary;
  final String uploadedBy;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.photoType,
    required this.filename,
    required this.filePath,
    this.caption,
    required this.isPrimary,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      photoType: json['photo_type'],
      filename: json['filename'],
      filePath: json['file_path'],
      caption: json['caption'],
      isPrimary: json['is_primary'] ?? false,
      uploadedBy: json['uploaded_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'photo_type': photoType,
      'filename': filename,
      'file_path': filePath,
      'caption': caption,
      'is_primary': isPrimary,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get photoTypeDisplayName {
    switch (photoType) {
      case 'front':
        return 'Front View';
      case 'back':
        return 'Back View';
      case 'left':
        return 'Left Side';
      case 'right':
        return 'Right Side';
      case 'interior':
        return 'Interior';
      case 'engine':
        return 'Engine Bay';
      case 'dashboard':
        return 'Dashboard';
      case 'damage':
        return 'Damage';
      case 'before':
        return 'Before Repair';
      case 'after':
        return 'After Repair';
      default:
        return photoType ?? 'General';
    }
  }

  @override
  String toString() {
    return 'Photo(id: $id, type: $photoType, entity: $entityType/$entityId, primary: $isPrimary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Photo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}