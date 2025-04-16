import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String quotationsCollection = 'quotations';
  final String productsCollection = 'products';

  // Add a new product with user ID and company ID
  Future<String> addProduct(Product product) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Create product with user ID
      final productData = product.toMap();
      productData['userId'] = user.uid;

      // Make sure companyId is included if provided
      if (product.companyId != null) {
        productData['companyId'] = product.companyId;
      }

      DocumentReference docRef =
          await _firestore.collection(productsCollection).add(productData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add product: $e');
    }
  }

  // Get only the current user's products, optionally filtered by company
  Stream<List<Product>> getProducts({String? companyId}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query query = _firestore
        .collection(productsCollection)
        .where('userId', isEqualTo: user.uid);

    // Add company filter if specified
    if (companyId != null) {
      query = query.where('companyId', isEqualTo: companyId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }

  // Update product with user verification
  Future<void> updateProduct(String id, Product product) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final productDoc =
          await _firestore.collection(productsCollection).doc(id).get();

      if (productDoc.data()?['userId'] != user.uid) {
        throw Exception('Unauthorized to update this product');
      }

      await _firestore
          .collection(productsCollection)
          .doc(id)
          .update(product.toMap());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product with user verification
  Future<void> deleteProduct(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final productDoc =
          await _firestore.collection(productsCollection).doc(id).get();

      if (productDoc.data()?['userId'] != user.uid) {
        throw Exception('Unauthorized to delete this product');
      }

      await _firestore.collection(productsCollection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Search within user's products and optionally filter by company
  Stream<List<Product>> searchProducts(String query, {String? companyId}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    Query queryRef = _firestore
        .collection(productsCollection)
        .where('userId', isEqualTo: user.uid);

    // Add company filter if specified
    if (companyId != null) {
      queryRef = queryRef.where('companyId', isEqualTo: companyId);
    }

    queryRef = queryRef
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff');

    return queryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    });
  }
}
