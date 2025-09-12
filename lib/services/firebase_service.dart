import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _companyProducts(String companyId) {
    return _firestore
        .collection('companies')
        .doc(companyId)
        .collection('products');
  }

  // Add product under a specific company
  Future<String> addProduct(Product product) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');
    if (product.companyId == null) throw Exception('Company ID is required');

    try {
      final productData = product.toMap()
        ..['userId'] = user.uid; // owner of the product

      final docRef =
          await _companyProducts(product.companyId!).add(productData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Get all products for a company
  Stream<List<Product>> getProducts({required String companyId}) {
    return _companyProducts(companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // Search products in a company by name
  Stream<List<Product>> searchProducts(String query,
      {required String companyId}) {
    return _companyProducts(companyId)
        .orderBy('name')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // Update product (only owner can update)
  Future<void> updateProduct(
      String companyId, String id, Product product) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final doc = await _companyProducts(companyId).doc(id).get();
    if (!doc.exists) throw Exception('Product not found');
    if (doc.data()?['userId'] != user.uid) {
      throw Exception('Unauthorized to update this product');
    }

    await _companyProducts(companyId).doc(id).update(product.toMap());
  }

  // Delete product (only owner can delete)
  Future<void> deleteProduct(String companyId, String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final doc = await _companyProducts(companyId).doc(id).get();
    if (!doc.exists) throw Exception('Product not found');
    if (doc.data()?['userId'] != user.uid) {
      throw Exception('Unauthorized to delete this product');
    }

    await _companyProducts(companyId).doc(id).delete();
  }
}
