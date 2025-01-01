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

enum ProductType { dimensionBased, standalone }

class Product {
  final String? id;
  final String? userId;
  final String name;
  final ProductType type;
  final double price;
  // final double pricePerUnit;
  final Dimension? height;
  final Dimension? width;
  final Dimension? depth;
  final String? description;
  final DateTime createdAt;

  Product({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.price,
    // required this.pricePerUnit,
    this.height,
    this.width,
    this.depth,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'userId': userId,  
      'name': name,
      'type': type.toString(),
      'price': price,
      'dimensions': {
        'height': height?.toMap(),
        'width': width?.toMap(),
        'depth': depth?.toMap(),
      },
      'description': description,
      'createdAt': createdAt,
    };
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> dimensions = data['dimensions'] ?? {};
    
    return Product(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: ProductType.values.firstWhere((e) => e.toString() == data['type'],
          orElse: () => ProductType.dimensionBased),
      price: (data['price'] ?? 0).toDouble(),
      height: dimensions['height'] != null
          ? Dimension.fromMap(dimensions['height'])
          : null,
      width: dimensions['width'] != null
          ? Dimension.fromMap(dimensions['width'])
          : null,
      depth: dimensions['depth'] != null
          ? Dimension.fromMap(dimensions['depth'])
          : null,
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    Map<String, dynamic> dimensions = map['dimensions'] ?? {};
    
    return Product(
      id: docId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      type: ProductType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ProductType.standalone
      ),
      price: (map['price'] ?? 0).toDouble(),
      height: dimensions['height'] != null ? Dimension.fromMap(dimensions['height']) : null,
      width: dimensions['width'] != null ? Dimension.fromMap(dimensions['width']) : null,
      depth: dimensions['depth'] != null ? Dimension.fromMap(dimensions['depth']) : null,
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && 
        other.id == id &&
        other.name == name &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(id, name, price);
}
