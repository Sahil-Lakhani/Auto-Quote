import 'dart:typed_data';
import 'package:auto_quote/models/company_model.dart';
import 'package:auto_quote/models/quote_model.dart';
import 'package:auto_quote/providers/quote_form_provider.dart';
import 'package:auto_quote/screens/quote_preview_screen.dart';
import 'package:auto_quote/services/firestore_service.dart';
import 'package:auto_quote/widgets/advance_payment_section.dart';
import 'package:auto_quote/widgets/company_info_section.dart';
import 'package:auto_quote/widgets/customer_info_section.dart';
import 'package:auto_quote/widgets/charges_section.dart';
import 'package:auto_quote/widgets/rooms_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuoteEditScreen extends StatefulWidget {
  final String quoteId;
  final File quotationFile;
  final Quote existingQuote;

  const QuoteEditScreen({
    super.key,
    required this.quoteId,
    required this.quotationFile,
    required this.existingQuote,
  });

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customerController = TextEditingController();
  final _customerphoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _roomTypeController = TextEditingController();
  final _transportController = TextEditingController();
  final _labourController = TextEditingController();
  final _advanceController = TextEditingController();

  final QuoteFormProvider _editProvider = QuoteFormProvider();
  final FirestoreService _firestoreService = FirestoreService();
  Company? _selectedCompany;

  @override
  void initState() {
    super.initState();

    _initializeProviderWithQuote(widget.existingQuote);

    _loadCompanyData(widget.existingQuote.companyName);

    _initializeTextControllers();

    _setupControllerListeners();
  }

  void _loadCompanyData(String companyName) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _firestoreService.getUserCompanies(user.uid).listen((companies) {
        for (final company in companies) {
          if (company.name == companyName) {
            setState(() {
              _selectedCompany = company;

              _editProvider.selectCompany(company);

              _companyController.text = company.name;
              _addressController.text = company.address;
              _phoneController.text = company.phone;
            });
            return;
          }
        }

        print('Company not found: $companyName');
      });
    } catch (e) {
      print('Error loading company data: $e');
    }
  }

  void _initializeProviderWithQuote(Quote quote) {

    _editProvider.companyName = quote.companyName.trim().isNotEmpty
        ? quote.companyName
        : 'Unknown Company';
    _editProvider.address =
        quote.address.trim().isNotEmpty ? quote.address : 'No address';
    _editProvider.phone =
        quote.phone.trim().isNotEmpty ? quote.phone : 'No phone';
    _editProvider.customerName = quote.clientName;
    _editProvider.date = DateFormat('dd/MM/yyyy').format(quote.date);
    _editProvider.rooms = List.from(quote.sections);
    _editProvider.transportCharges = quote.transportCharges;
    _editProvider.laborCharges = quote.laborCharges;
    _editProvider.toggleGst(quote.isGstEnabled);
    _editProvider.toggleAdvancePayment(quote.advancePaymentPercentage != null);
    if (quote.advancePaymentPercentage != null) {
      _editProvider.updateAdvancePaymentPercentage(
          quote.advancePaymentPercentage.toString());
    }
  }

  void _initializeTextControllers() {
    _companyController.text = _editProvider.companyName;
    _addressController.text = _editProvider.address;
    _phoneController.text = _editProvider.phone;
    _customerController.text = _editProvider.customerName;
    _customerphoneController.text = _editProvider.customerPhone;
    _dateController.text = _editProvider.date;
    _transportController.text = _editProvider.transportCharges.toString();
    _labourController.text = _editProvider.laborCharges.toString();
    _advanceController.text =
        _editProvider.advancePaymentPercentage?.toString() ?? '50';
  }

  void _setupControllerListeners() {
    _customerController.addListener(() {
      _editProvider.updateCustomerName(_customerController.text);
    });

    _customerphoneController.addListener(() {
      _editProvider.updateCustomerPhone(_customerphoneController.text);
    });

    _dateController.addListener(() {
      _editProvider.updateDate(_dateController.text);
    });

    _transportController.addListener(() {
      _editProvider.updateTransportCharges(_transportController.text);
    });

    _labourController.addListener(() {
      _editProvider.updateLaborCharges(_labourController.text);
    });

    _advanceController.addListener(() {
      if (_editProvider.isAdvancePaymentEnabled) {
        _editProvider.updateAdvancePaymentPercentage(_advanceController.text);
      }
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _customerController.dispose();
    _customerphoneController.dispose();
    _dateController.dispose();
    _roomTypeController.dispose();
    _transportController.dispose();
    _labourController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  void _addRoom() {
    if (_roomTypeController.text.isEmpty) return;
    _editProvider.addRoom(QuoteRoomType(
      title: _roomTypeController.text,
      items: [],
      roomTotal: _editProvider.roomTotal,
    ));
    _roomTypeController.clear();
  }

  Quote _createQuote() {
    Uint8List? logoBytes;

    if (_editProvider.logoFile != null) {
      logoBytes = _editProvider.logoFile!.readAsBytesSync();
    } else if (widget.existingQuote.logoBytes != null) {
      logoBytes = widget.existingQuote.logoBytes;
    }

    final companyName =
        _selectedCompany?.name ?? widget.existingQuote.companyName;
    final companyAddress =
        _selectedCompany?.address ?? widget.existingQuote.address;
    final companyPhone = _selectedCompany?.phone ?? widget.existingQuote.phone;

    return Quote(
      companyName: companyName,
      address: companyAddress,
      logoBytes: logoBytes,
      phone: companyPhone,
      clientName: _editProvider.customerName,
      transportCharges: _editProvider.transportCharges,
      laborCharges: _editProvider.laborCharges,
      date: _editProvider.date.isNotEmpty
          ? DateFormat('dd/MM/yyyy').parse(_editProvider.date)
          : DateTime.now(),
      sections: _editProvider.rooms,
      isGstEnabled: _editProvider.isGstEnabled,
      subtotal: _editProvider.subtotal,
      cgst: _editProvider.cgst,
      sgst: _editProvider.sgst,
      grandTotal: _editProvider.grandTotal,
      advancePaymentPercentage: _editProvider.advancePaymentPercentage,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      _dateController.text = formattedDate;
      _editProvider.updateDate(formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _editProvider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Quote'),
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.bug_report),
            //   onPressed: () {
            //     print(
            //         'DEBUG: Company Name: ${widget.existingQuote.companyName}');
            //     print('DEBUG: Address: ${widget.existingQuote.address}');
            //     print('DEBUG: Phone: ${widget.existingQuote.phone}');
            //     print(
            //         'DEBUG: Has Logo: ${widget.existingQuote.logoBytes != null}');
            //     print('SELECTED COMPANY: ${_selectedCompany?.name}');
            //     print('SELECTED ADDRESS: ${_selectedCompany?.address}');
            //     print('SELECTED PHONE: ${_selectedCompany?.phone}');

            //     _loadCompanyData(widget.existingQuote.companyName);

            //     ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(content: Text('Company info refreshed')));
            //   },
            // ),
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: () {
                final quote = _createQuote();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuotePreviewScreen(
                      quote: quote,
                      isEditing: true,
                      quoteId: widget.quoteId,
                      quotationFile: widget.quotationFile,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Company Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Read Only',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          _buildCompanyInfoRow(
                            label: 'Company:',
                            value: _selectedCompany?.name ??
                                widget.existingQuote.companyName,
                            fallback: 'No company name available',
                          ),
                          const SizedBox(height: 8),
                          _buildCompanyInfoRow(
                            label: 'Address:',
                            value: _selectedCompany?.address ??
                                widget.existingQuote.address,
                            fallback: 'No address available',
                          ),
                          const SizedBox(height: 8),
                          _buildCompanyInfoRow(
                            label: 'Phone:',
                            value: _selectedCompany?.phone ??
                                widget.existingQuote.phone,
                            fallback: 'No phone number available',
                          ),
                          const SizedBox(height: 8),
                          _buildCompanyInfoRow(
                            label: 'GST:',
                            value: _selectedCompany?.gstNumber ??
                                'No GST information',
                            fallback: 'No GST information available',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Editable Information',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomerInfoSection(
                    customerController: _customerController,
                    phoneController: _customerphoneController,
                    dateController: _dateController,
                    selectDate: _selectDate,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Room',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _roomTypeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Room Type',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _addRoom,
                                child: const Text('Add Room'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const RoomsSection(),
                  const SizedBox(height: 16),
                  ChargesSection(
                    transportController: _transportController,
                    labourController: _labourController,
                  ),
                  const SizedBox(height: 16),
                  AdvancePaymentSection(
                    advanceController: _advanceController,
                  ),
                  const SizedBox(height: 16),
                  _buildSummary(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Consumer<QuoteFormProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Text('GST'),
                        const SizedBox(width: 8),
                        Switch(
                          value: provider.isGstEnabled,
                          onChanged: (value) => provider.toggleGst(value),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Subtotal', provider.subtotal),
                if (provider.isGstEnabled) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow('CGST (9%)', provider.cgst),
                  const SizedBox(height: 8),
                  _buildSummaryRow('SGST (9%)', provider.sgst),
                ],
                const Divider(),
                _buildSummaryRow('Grand Total', provider.grandTotal,
                    isTotal: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyInfoRow({
    required String label,
    required String value,
    required String fallback,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isNotEmpty ? value : fallback,
            style: TextStyle(
              fontSize: 16,
              color: value.trim().isNotEmpty ? Colors.black : Colors.grey,
              fontStyle:
                  value.trim().isNotEmpty ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
