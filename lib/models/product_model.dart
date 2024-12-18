import 'package:cloud_firestore/cloud_firestore.dart';

class Dimension {
  final int feet;
  final int inches;

  const Dimension({required this.feet, required this.inches});

  String get formatted => '${feet}\'${inches}"';

  Map<String, dynamic> toMap() => {'feet': feet, 'inches': inches};

  factory Dimension.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const Dimension(feet: 0, inches: 0);
    return Dimension(
      feet: map['feet'] ?? 0,
      inches: map['inches'] ?? 0,
    );
  }

  static Dimension? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final parts = value.split(' ');
    if (parts.length != 2) return null;
    
    final feet = int.tryParse(parts[0].replaceAll("'", ""));
    final inches = int.tryParse(parts[1].replaceAll('"', ""));
    
    if (feet == null || inches == null) return null;
    return Dimension(feet: feet, inches: inches);
  }
}

class Product {
  final String? id;
  final String name;
  final double pricePerUnit;
  final Dimension? height;
  final Dimension? width;
  final Dimension? depth;
  final String? other;
  final DateTime createdAt;

  Product({
    this.id,
    required this.name,
    required this.pricePerUnit,
    this.height,
    this.width,
    this.depth,
    this.other,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'pricePerUnit': pricePerUnit,
      'dimensions': {
        'height': height?.toMap(),
        'width': width?.toMap(),
        'depth': depth?.toMap(),
      },
      'other': other,
      'createdAt': createdAt,
    };
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> dimensions = data['dimensions'] ?? {};
    
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      pricePerUnit: (data['pricePerUnit'] ?? 0).toDouble(),
      height: dimensions['height'] != null ? Dimension.fromMap(dimensions['height']) : null,
      width: dimensions['width'] != null ? Dimension.fromMap(dimensions['width']) : null,
      depth: dimensions['depth'] != null ? Dimension.fromMap(dimensions['depth']) : null,
      other: data['other'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
