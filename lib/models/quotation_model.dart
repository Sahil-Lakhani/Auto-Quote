import 'package:cloud_firestore/cloud_firestore.dart';
import 'quote_model.dart';

class Quotation {
  final String? id;
  final String userId;
  final String pdfUrl;
  final String companyName;
  final String clientName;
  final String address;
  final String phone;
  final DateTime date;
  final List<QuoteRoomType> sections;
  final int transportCharges;
  final int laborCharges;
  final double subtotal;
  final bool isGstEnabled;
  final double cgst;
  final double sgst;
  final double grandTotal;
  final DateTime createdAt;

  Quotation({
    this.id,
    required this.userId,
    required this.pdfUrl,
    required this.companyName,
    required this.clientName,
    required this.address,
    required this.phone,
    required this.date,
    required this.sections,
    required this.transportCharges,
    required this.laborCharges,
    required this.subtotal,
    required this.isGstEnabled,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pdfUrl': pdfUrl,
      'companyName': companyName,
      'clientName': clientName,
      'address': address,
      'phone': phone,
      'date': date,
      'sections': sections.map((section) => {
        'title': section.title,
        'items': section.items.map((item) => {
          'description': item.description,
          'dimensions': item.dimensions,
          'quantity': item.quantity,
          'pricePerSqft': item.pricePerSqft,
          'unitPrice': item.unitPrice,
          'totalPrice': item.totalPrice,
        }).toList(),
        'roomTotal': section.roomTotal,
      }).toList(),
      'transportCharges': transportCharges,
      'laborCharges': laborCharges,
      'subtotal': subtotal,
      'isGstEnabled': isGstEnabled,
      'cgst': cgst,
      'sgst': sgst,
      'grandTotal': grandTotal,
      'createdAt': createdAt,
    };
  }

  factory Quotation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Quotation(
      id: doc.id,
      userId: data['userId'] ?? '',
      pdfUrl: data['pdfUrl'] ?? '',
      companyName: data['companyName'] ?? '',
      clientName: data['clientName'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      sections: (data['sections'] as List).map((section) => QuoteRoomType(
        title: section['title'],
        items: (section['items'] as List).map((item) => QuoteItem(
          description: item['description'],
          dimensions: item['dimensions'],
          quantity: item['quantity'],
          pricePerSqft: (item['pricePerSqft'] ?? 0).toDouble(),
          unitPrice: (item['unitPrice'] ?? 0).toDouble(),
          totalPrice: (item['totalPrice'] ?? 0).toDouble(),
        )).toList(),
        roomTotal: (section['roomTotal'] ?? 0).toDouble(),
      )).toList(),
      transportCharges: data['transportCharges'] ?? 0,
      laborCharges: data['laborCharges'] ?? 0,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      isGstEnabled: data['isGstEnabled'] ?? false,
      cgst: (data['cgst'] ?? 0).toDouble(),
      sgst: (data['sgst'] ?? 0).toDouble(),
      grandTotal: (data['grandTotal'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}