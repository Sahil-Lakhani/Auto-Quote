// storage_service.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote_model.dart';

class StorageService {
  static const String folderName = 'AutoQuote';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create AutoQuote directory
  Future<Directory> getQuoteDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Get the external storage directory for Android
      directory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      // Get the documents directory for iOS
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Could not access storage directory');
    }

    // Create AutoQuote directory if it doesn't exist
    final quoteDir = Directory('${directory.path}/$folderName');
    if (!await quoteDir.exists()) {
      await quoteDir.create(recursive: true);
    }

    return quoteDir;
  }

  // Save PDF file and store quote data in Firebase
  Future<void> saveQuoteAndPdf(Quote quote, List<int> pdfBytes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final quoteDir = await getQuoteDirectory();
    final DateTime now = DateTime.now();
    final String dateStr =
        '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';
    final fileName = '${quote.clientName}_$dateStr.pdf';
    final file = File('${quoteDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    await _firestore.collection('quotations').add({
      'userId': user.uid,
      'companyName': quote.companyName,
      'clientName': quote.clientName,
      'date': quote.date,
      'sections': quote.sections
          .map((section) => {
                'title': section.title,
                'roomTotal': section.roomTotal,
                'items': section.items
                    .map((item) => {
                          'description': item.description,
                          'dimensions': item.dimensions,
                          'quantity': item.quantity,
                          'unitPrice': item.unitPrice,
                          'totalPrice': item.totalPrice,
                        })
                    .toList(),
              })
          .toList(),
      'transportCharges': quote.transportCharges,
      'laborCharges': quote.laborCharges,
      'subtotal': quote.subtotal,
      'isGstEnabled': quote.isGstEnabled,
      'cgst': quote.cgst,
      'sgst': quote.sgst,
      'grandTotal': quote.grandTotal,
      'pdfPath': file.path,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all saved PDFs
  Future<List<File>> getSavedPdfs() async {
    final quoteDir = await getQuoteDirectory();
    final List<FileSystemEntity> entities = await quoteDir.list().toList();
    return entities
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.pdf'))
        .toList();
  }

  // Share PDF
  Future<void> sharePdf(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Sharing Quote PDF');
  }

  // Delete PDF and its data from Firebase
  Future<void> deletePdf(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Delete from Firebase
    final querySnapshot = await _firestore
        .collection('quotations')
        .where('userId', isEqualTo: user.uid)
        .where('pdfPath', isEqualTo: file.path)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete local file
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Update existing PDF and quotation data in Firebase
  Future<void> updateQuoteAndPdf(
    String quoteId,
    Quote quote,
    List<int> pdfBytes,
    File quotationFile,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Get the directory path from the existing file
    final directory = quotationFile.parent;
    final DateTime now = DateTime.now();
    final String dateStr =
        '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';
    final fileName = '${quote.clientName}_$dateStr.pdf';

    // Create a new file or overwrite the existing one
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfBytes);

    // Update the document in Firestore
    await _firestore.collection('quotations').doc(quoteId).update({
      'clientName': quote.clientName,
      'date': quote.date,
      'sections': quote.sections
          .map((section) => {
                'title': section.title,
                'roomTotal': section.roomTotal,
                'items': section.items
                    .map((item) => {
                          'description': item.description,
                          'dimensions': item.dimensions,
                          'quantity': item.quantity,
                          'unitPrice': item.unitPrice,
                          'totalPrice': item.totalPrice,
                        })
                    .toList(),
              })
          .toList(),
      'transportCharges': quote.transportCharges,
      'laborCharges': quote.laborCharges,
      'subtotal': quote.subtotal,
      'isGstEnabled': quote.isGstEnabled,
      'cgst': quote.cgst,
      'sgst': quote.sgst,
      'grandTotal': quote.grandTotal,
      'pdfPath': file.path,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If the filename changed, delete the old file
    if (quotationFile.path != file.path && await quotationFile.exists()) {
      await quotationFile.delete();
    }
  }
}
