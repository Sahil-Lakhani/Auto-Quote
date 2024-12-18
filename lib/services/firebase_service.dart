import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String productsCollection = 'products';

  // Add a new product
  Future<String> addProduct(Product product) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(productsCollection)
          .add(product.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Get all products
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection(productsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  // Update a product
  Future<void> updateProduct(String id, Product product) async {
    try {
      await _firestore
          .collection(productsCollection)
          .doc(id)
          .update(product.toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete a product
  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(productsCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Search products
  Stream<List<Product>> searchProducts(String query) {
    return _firestore
        .collection(productsCollection)
        .orderBy('name')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }
}
