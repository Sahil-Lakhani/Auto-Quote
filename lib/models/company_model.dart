import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String address;
  final String phone; // Changed from int to String to match TextField
  final String gstNumber;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.gstNumber,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'gstNumber': gstNumber,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': createdAt,
    };
  }

  factory Company.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone']?.toString() ?? '',
      gstNumber: data['gstNumber'],
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
