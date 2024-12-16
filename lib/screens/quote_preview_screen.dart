import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/quote_model.dart';
import '../services/pdf_service.dart';

class QuotePreviewScreen extends StatelessWidget {
  final Quote quote;

  const QuotePreviewScreen({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Preview'),
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateQuote(quote),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
