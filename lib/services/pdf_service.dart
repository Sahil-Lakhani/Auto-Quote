import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/quote_model.dart';

class PdfService {
  static Future<Uint8List> generateQuote(Quote quote) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            _buildHeader(quote),
            pw.SizedBox(height: 20),
            ...quote.sections.map((section) => _buildSection(section)),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              quote.companyName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Container(
              width: 100,
              height: 50,
              child: pw.Center(
                child: pw.Text('Logo'),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('Address: ${quote.address}'),
        pw.Text('Phone: ${quote.phone}'),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Client: ${quote.clientName}'),
            pw.Text('Date: ${DateFormat('dd MMM yyyy').format(quote.date)}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSection(QuoteSection section) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          color: PdfColors.orange100,
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            section.title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        _buildItemsTable(section.items),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<QuoteItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.orange100,
          ),
          children: [
            _buildTableCell('#', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Dimensions', isHeader: true),
            _buildTableCell('Area/No.S', isHeader: true),
            _buildTableCell('Unit Price ', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Data rows
        ...items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell(index.toString()),
              _buildTableCell(item.description),
              _buildTableCell(item.dimensions ?? ''),
              _buildTableCell(item.areaOrQuantity.toString()),
              _buildTableCell(item.unitPrice.toStringAsFixed(2)),
              _buildTableCell(item.totalPrice.toStringAsFixed(2)),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Thank you for choosing us!',
        style: pw.TextStyle(
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey700,
        ),
      ),
    );
  }
}
