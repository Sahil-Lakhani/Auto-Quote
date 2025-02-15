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
            pw.SizedBox(height: 20),
            _buildSummary(quote),
            pw.SizedBox(height: 30),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderInfo(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 60,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
              fontSize: 11,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHeader(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      quote.companyName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.only(left: 2),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildHeaderInfo('Address', quote.address),
                          pw.SizedBox(height: 4),
                          _buildHeaderInfo('Phone', quote.phone),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (quote.logoBytes != null)
                pw.Container(
                  width: 120,
                  height: 60,
                  margin: const pw.EdgeInsets.only(left: 20),
                  child: pw.Image(
                    pw.MemoryImage(quote.logoBytes!),
                    fit: pw.BoxFit.contain,
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        // Quote details section
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'QUOTATION FOR:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    quote.clientName,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'DATE:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    DateFormat('dd/MM/yyyy').format(quote.date),
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSection(QuoteRoomType section) {
    double total =
        section.items.fold(0.0, (sum, item) => sum + item.totalPrice);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          color: PdfColors.blue100,
          child: pw.Text(
            section.title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        _buildItemsTable(section.items),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Room Total: ',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                total.toStringAsFixed(2),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<QuoteItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5), // #
        1: const pw.FlexColumnWidth(1.5), // Product name
        2: const pw.FlexColumnWidth(1.5), // Dimensions
        3: const pw.FlexColumnWidth(1.0), // Price/Sqft
        4: const pw.FlexColumnWidth(1.0), // Total Sqft
        5: const pw.FlexColumnWidth(0.5), // Quantity
        6: const pw.FlexColumnWidth(1.0), // Unit Price
        7: const pw.FlexColumnWidth(1.0), // Total
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('#', isHeader: true),
            _buildTableCell('Product Name', isHeader: true),
            _buildTableCell('Dimensions', isHeader: true),
            _buildTableCell('Price Sqft', isHeader: true, isCenter: true),
            _buildTableCell('Total  Sqft', isHeader: true, isCenter: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Unit Price', isHeader: true, isCenter: true),
            _buildTableCell('Total', isHeader: true, isCenter: true),
          ],
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _buildTableCell(index.toString()),
            _buildTableCell(item.description.isEmpty ? '-' : item.description),
              _buildTableCell(
              (item.dimensions?.isEmpty ?? true) ? '-' : item.dimensions!
            ),
              _buildTableCell(
                  item.pricePerSqft == null || item.pricePerSqft == 0
                      ? '-'
                      : item.pricePerSqft!.toStringAsFixed(2),
                  isAmount: true,
              isCenter: false
            ),
              _buildTableCell(
                  item.totalSqft == null || item.totalSqft == 0
                      ? '-'
                      : item.totalSqft!.toStringAsFixed(2),
                  isAmount: false,
                isCenter: true
              ),
            _buildTableCell(
              item.quantity == null || item.quantity == 0 
                  ? '-'
                : item.quantity.toString()
            ),
              _buildTableCell(
              item.unitPrice == 0 
                ? '-' 
                : item.unitPrice.toStringAsFixed(2),
                  isAmount: true,
              isCenter: false
            ),
              _buildTableCell(
                  item.totalPrice == 0
                      ? '-'
                      : item.totalPrice.toStringAsFixed(2),
                  isAmount: true,
              isCenter: false
            ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildSummary(Quote quote) {
    final summaryItems = [
      if (quote.transportCharges > 0)
        {
          'label': 'Transport Charges',
          'amount': quote.transportCharges.toDouble()
        },
      if (quote.laborCharges > 0)
        {'label': 'Labour Charges', 'amount': quote.laborCharges.toDouble()},
      {'label': 'Subtotal', 'amount': quote.subtotal},
      // Only include GST items if GST is enabled
      if (quote.isGstEnabled) ...[
        {'label': 'CGST (9%)', 'amount': quote.cgst},
        {'label': 'SGST (9%)', 'amount': quote.sgst},
      ],
    ];

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        child: pw.Column(
          children: [
            ...summaryItems.map((item) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(item['label'] as String),
                      pw.Text(
                        (item['amount'] as double).toStringAsFixed(2),
                      ),
                    ],
                  ),
                )),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.blue100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Grand Total',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    quote.grandTotal.toStringAsFixed(2),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, bool isAmount = false, bool isCenter = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
        textAlign: isCenter
            ? pw.TextAlign.center
            : (isAmount ? pw.TextAlign.right : pw.TextAlign.left),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Thank you message column
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Thank you for choosing us!',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'For any queries, please contact us.',
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              // Signature column
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 150,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Authorized Signatory',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
