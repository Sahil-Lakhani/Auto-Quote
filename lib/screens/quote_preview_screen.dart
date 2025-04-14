import 'package:auto_quote/screens/profile_screen.dart';
import 'package:auto_quote/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
// import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quote_model.dart';
import '../services/pdf_service.dart';
// import '../services/firebase_service.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class QuotePreviewScreen extends StatefulWidget {
  final Quote quote;
  final bool isEditing;
  final String? quoteId;
  final File? quotationFile;

  const QuotePreviewScreen({
    super.key,
    required this.quote,
    this.isEditing = false,
    this.quoteId,
    this.quotationFile,
  });

  @override
  State<QuotePreviewScreen> createState() => _QuotePreviewScreenState();
}

class _QuotePreviewScreenState extends State<QuotePreviewScreen> {
  bool _isSaving = false;

  Future<void> _saveQuotation() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Generate and save PDF
      final pdfBytes = await PdfService.generateQuote(widget.quote);

      if (widget.isEditing &&
          widget.quoteId != null &&
          widget.quotationFile != null) {
        // Update existing quotation
        await StorageService().updateQuoteAndPdf(
          widget.quoteId!,
          widget.quote,
          pdfBytes,
          widget.quotationFile!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quotation updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      } else {
        // Create new quotation
        await StorageService().saveQuoteAndPdf(widget.quote, pdfBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quotation saved successfully'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving quotation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Quote Preview' : 'Quote Preview'),
        actions: [
          // Save button with improved visibility
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saveQuotation,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.isEditing ? Icons.update : Icons.save,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.isEditing ? 'Update' : 'Save',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          // Add print button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {
                Printing.layoutPdf(
                  onLayout: (format) => PdfService.generateQuote(widget.quote),
                );
              },
              icon: const Icon(Icons.print),
              tooltip: 'Print Quote',
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateQuote(widget.quote),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
