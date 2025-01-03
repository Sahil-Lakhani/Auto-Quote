import 'package:cloud_firestore/cloud_firestore.dart';

class Dimension {
  final int feet;
  final int inches;

  const Dimension({required this.feet, required this.inches});

  String get formatted => '${feet}\'${inches}"';

  double get toDecimalFeet => feet + (inches / 12);

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
  final double? pricePerSqft;
  final double price;
  final Dimension? height;
  final Dimension? width;
  final Dimension? depth;
  final String? description;
  final DateTime createdAt;

  double get calculatedPrice {
    if (type == ProductType.dimensionBased &&
        height != null &&
        width != null &&
        pricePerSqft != null) {
      return height!.toDecimalFeet * width!.toDecimalFeet * pricePerSqft!;
    }
    return price;
  }

  double get totalSquareFeet {
    if (type == ProductType.dimensionBased && height != null && width != null) {
      return height!.toDecimalFeet * width!.toDecimalFeet;
    }
    return 0;
  }

  Product({
    this.id,
    this.userId,
    required this.name,
    required this.type,
    double? price,
    this.pricePerSqft,
    this.height,
    this.width,
    this.depth,
    this.description,
    DateTime? createdAt,
  })  : price = type == ProductType.standalone
            ? (price ?? 0)
            : ((height != null && width != null && pricePerSqft != null)
                ? height.toDecimalFeet * width.toDecimalFeet * pricePerSqft
                : 0),
        createdAt = createdAt ?? DateTime.now() {
    // Validation
    if (type == ProductType.standalone && price == null) {
      throw ArgumentError('Price is required for standalone products');
    }
    if (type == ProductType.dimensionBased) {
      if (pricePerSqft == null) {
        throw ArgumentError(
            'Price per square foot is required for dimension-based products');
      }
      if (height == null || width == null) {
        throw ArgumentError(
            'Height and width are required for dimension-based products');
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'userId': userId,  
      'name': name,
      'type': type.toString(),
      'price': calculatedPrice,
      'pricePerSqft': type == ProductType.dimensionBased ? pricePerSqft : null,
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
    
    final ProductType type = ProductType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => ProductType.standalone);

    if (type == ProductType.standalone) {
    return Product(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
        type: type,
      price: (data['price'] ?? 0).toDouble(),
        description: data['description'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    } else {
      return Product(
        id: doc.id,
        userId: data['userId'] ?? '',
        name: data['name'] ?? '',
        type: type,
        pricePerSqft: (data['pricePerSqft'] ?? 0).toDouble(),
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
  }

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    Map<String, dynamic> dimensions = map['dimensions'] ?? {};
    
    final ProductType type = ProductType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ProductType.standalone);

    if (type == ProductType.standalone) {
    return Product(
      id: docId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
        type: type,
      price: (map['price'] ?? 0).toDouble(),
        description: map['description'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );
    } else {
      return Product(
        id: docId,
        userId: map['userId'] ?? '',
        name: map['name'] ?? '',
        type: type,
        pricePerSqft: (map['pricePerSqft'] ?? 0).toDouble(),
        height: dimensions['height'] != null
            ? Dimension.fromMap(dimensions['height'])
            : null,
        width: dimensions['width'] != null
            ? Dimension.fromMap(dimensions['width'])
            : null,
        depth: dimensions['depth'] != null
            ? Dimension.fromMap(dimensions['depth'])
            : null,
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
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
