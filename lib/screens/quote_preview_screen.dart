import 'package:auto_quote/screens/profile_screen.dart';
import 'package:auto_quote/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
// import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quote_model.dart';
import '../services/pdf_service.dart';
// import '../services/firebase_service.dart';

class QuotePreviewScreen extends StatefulWidget {
  final Quote quote;

  const QuotePreviewScreen({super.key, required this.quote});

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
      await StorageService().saveQuoteAndPdf(widget.quote, pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quotation saved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
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
        title: const Text('Quote Preview'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Quote'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: _saveQuotation,
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
