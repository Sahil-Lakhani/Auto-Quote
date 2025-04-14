// ignore_for_file: avoid_print

import 'dart:math';

import 'package:auto_quote/models/company_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUser(String uid, String email, String? displayName) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName ?? '',
        'lastSignIn': FieldValue.serverTimestamp(),
        'companies': [], // Initialize an empty array for companies
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  Future<String> generateCompanyInviteCode(String companyId) async {
    //? have to decide wheather to generate unique code or not and 
    //? have to decide weather to for how long and also how to show it in app 
    try {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      final code =
          List.generate(6, (index) => chars[random.nextInt(chars.length)])
              .join();

      // Create invite document
      await _firestore.collection('companyInvites').doc(code).set({
        'companyId': companyId,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 1))),
      });
      return code;
    } catch (e) {
      print('Error generating invite code: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> verifyAndJoinCompany(String code, String userId) async {
    try {
      final inviteDoc = await _firestore.collection('companyInvites').doc(code).get();
      
      if (!inviteDoc.exists) {
        return {'success': false, 'message': 'Invalid invite code'};
      }

      final inviteData = inviteDoc.data()!;
      
      // Check if code is expired
      final expiresAt = inviteData['expiresAt'] as Timestamp;
      if (expiresAt.toDate().isBefore(DateTime.now())) {
        // Delete expired code
        await _firestore.collection('companyInvites').doc(code).delete();
        return {'success': false, 'message': 'Invite code has expired'};
      }

      // Get company data
      final companyId = inviteData['companyId'] as String;
      final companyDoc = await _firestore.collection('companies').doc(companyId).get();
      
      if (!companyDoc.exists) {
        return {'success': false, 'message': 'Company no longer exists'};
      }

      final companyData = companyDoc.data()!;
      
      // Check if user is already a member
      if ((companyData['memberIds'] as List).contains(userId)) {
        return {'success': false, 'message': 'You are already a member of this company'};
      }

      // Join company
      await joinCompany(companyId, userId);
      

      await _firestore.collection('companyInvites').doc(code).delete();

      return {
        'success': true,
        'message': 'Successfully joined company',
        'companyName': companyData['name'],
      };
    } catch (e) {
      print('Error verifying invite code: $e');
      return {'success': false, 'message': 'Error joining company: $e'};
    }
  }

  Future<String> createCompany({
    required String name,
    required String ownerId,
    required String address ,
    required String phone ,
    String gstNumber = '',
  }) async {
    try {
      final company = {
        'name': name,
        'ownerId': ownerId,
        'address': address,
        'phone': phone,
        'gstNumber': gstNumber,
        'memberIds': [ownerId],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('companies').add(company);

      // Update user's companies list
      await _firestore.collection('users').doc(ownerId).update({
        'companies': FieldValue.arrayUnion([docRef.id])
      });

      return docRef.id;
    } catch (e) {
      print('Error creating company: $e');
      rethrow;
    }
  }

  Future<void> deleteCompany(String companyId) async {
    try {
      await _firestore.collection('companies').doc(companyId).delete();
    } catch (e) {
      print('Error deleting company: $e');
      rethrow;
    }
  }

  Future<void> updateCompany({
    required String companyId,
    String? name,
    String? address,
    String? phone,
    String? gstNumber,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (address != null) updateData['address'] = address;
      if (phone != null) updateData['phone'] = phone;
      if (gstNumber != null) updateData['gstNumber'] = gstNumber;
      if (updateData.isNotEmpty) {
        await _firestore
            .collection('companies')
            .doc(companyId)
            .update(updateData);
      }
    } catch (e) {
      print('Error updating company: $e');
      rethrow;
    }
  }

  Future<void> joinCompany(String companyId, String userId) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'memberIds': FieldValue.arrayUnion([userId])
      });

      await _firestore.collection('users').doc(userId).update({
        'companies': FieldValue.arrayUnion([companyId])
      });
    } catch (e) {
      print('Error joining company: $e');
      rethrow;
    }
  }

  Future<void> leaveCompany(String companyId, String userId) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'memberIds': FieldValue.arrayRemove([userId])
      });

      await _firestore.collection('users').doc(userId).update({
        'companies': FieldValue.arrayRemove([companyId])
      });
    } catch (e) {
      print('Error leaving company: $e');
      rethrow;
    }
  }

  Stream<List<Company>> getUserCompanies(String userId) {
    return _firestore
        .collection('companies')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList();
    });
  }

  Future<Company?> getCompanyById(String companyId) async {
    try {
      final doc = await _firestore.collection('companies').doc(companyId).get();
      if (doc.exists) {
        return Company.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting company: $e');
      rethrow;
    }
  }
}
