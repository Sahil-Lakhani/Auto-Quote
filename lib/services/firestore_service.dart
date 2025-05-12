// ignore_for_file: avoid_print

import 'dart:math';

import 'package:auto_quote/models/company_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

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
    try {
      // First get the current invite code to delete it later
      final companyDoc = await _firestore.collection('companies').doc(companyId).get();
      final oldInviteCode = companyDoc.data()?['inviteCode'] as String?;
      
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();
      String code;
      bool isUnique = false;
      
      // Keep generating codes until we find a unique one
      while (!isUnique) {
        // Generate a random 6-character code
        code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
        
        // Check if code exists in the invite_codes collection
        final codeDoc = await _firestore.collection('invite_codes').doc(code).get();
        
        if (!codeDoc.exists) {
          isUnique = true;
          
          // Add the code to the invite_codes collection
          await _firestore.collection('invite_codes').doc(code).set({
            'companyId': companyId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          // Update company with new invite code
          await _firestore.collection('companies').doc(companyId).update({
            'inviteCode': code,
          });
          
          // Delete the old invite code from the collection
          if (oldInviteCode != null && oldInviteCode.isNotEmpty) {
            await _firestore.collection('invite_codes').doc(oldInviteCode).delete();
          }
          
          return code;
        }
      }
      
      // This should never happen since we return inside the while loop when we find a unique code
      throw Exception('Failed to generate unique invite code');
    } catch (e) {
      print('Error generating invite code: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> verifyAndJoinCompany(
      String code, String userId) async {
    try {
      // Check invite_codes collection first
      final codeDoc =
          await _firestore.collection('invite_codes').doc(code).get();

      if (!codeDoc.exists) {
        return {'success': false, 'message': 'Invalid invite code'};
      }

      final data = codeDoc.data()!;
      final companyId = data['companyId'] as String;

      // Get the company document
      final companyDoc =
          await _firestore.collection('companies').doc(companyId).get();

      if (!companyDoc.exists) {
        return {'success': false, 'message': 'Company no longer exists'};
      }

      final companyData = companyDoc.data()!;

      // Check if user is already a member
      if ((companyData['memberIds'] as List).contains(userId)) {
        return {
          'success': false,
          'message': 'You are already a member of this company'
        };
      }

      // Join company
      await joinCompany(companyId, userId);

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
    required String address,
    required String gstNumber,
    required String phone,
  }) async {
    final companyRef = _firestore.collection('companies').doc();
    await companyRef.set({  
      'name': name,
      'ownerId': ownerId,
      'address': address,
      'gstNumber': gstNumber,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
      'memberIds': [ownerId],
      'inviteCode': '',
    });
    return companyRef.id;
  }

  Future<void> deleteCompany(String companyId) async {
    try {
      // Get company to find invite code
      final companyDoc =
          await _firestore.collection('companies').doc(companyId).get();

      if (companyDoc.exists) {
        final companyData = companyDoc.data();
        final inviteCode = companyData?['inviteCode'] as String?;

        // Delete the invite code document if it exists
        if (inviteCode != null && inviteCode.isNotEmpty) {
          await _firestore.collection('invite_codes').doc(inviteCode).delete();
        }
      }

      // Delete the company document
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
