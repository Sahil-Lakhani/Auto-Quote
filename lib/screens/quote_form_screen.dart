import 'dart:typed_data';
import 'dart:async';
import 'package:auto_quote/models/quote_model.dart';
import 'package:auto_quote/providers/quote_form_provider.dart';
import 'package:auto_quote/screens/quote_preview_screen.dart';
import 'package:auto_quote/screens/create_company_screen.dart';
import 'package:auto_quote/widgets/advance_payment_section.dart';
import 'package:auto_quote/widgets/company_info_section.dart';
import 'package:auto_quote/widgets/customer_info_section.dart';
import 'package:auto_quote/widgets/charges_section.dart';
import 'package:auto_quote/widgets/rooms_section.dart';
import 'package:auto_quote/widgets/notes_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:auto_quote/models/company_model.dart';
import 'package:auto_quote/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_quote/theme.dart';

class QuoteFormScreen extends StatefulWidget {
  final bool isEditing;
  final String? quoteId;
  final File? quotationFile;
  final Quote? existingQuote;

  const QuoteFormScreen({
    super.key,
    this.isEditing = false,
    this.quoteId,
    this.quotationFile,
    this.existingQuote,
  });

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
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
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  List<Company>? _userCompanies;
  StreamSubscription? _companiesSubscription;

  // Color constants replaced by theme.dart
  static const Color textColor = kPrimaryTextColor;

  @override
  void initState() {
    super.initState();
    _loadUserCompanies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuoteFormProvider>();

      // If editing, initialize form with existing quote data
      if (widget.isEditing && widget.existingQuote != null) {
        final quote = widget.existingQuote!;

        // Pre-fill the provider with existing quote data
        provider.companyName = quote.companyName;
        provider.address = quote.address;
        provider.phone = quote.phone;
        provider.customerName = quote.clientName;
        provider.date = DateFormat('dd/MM/yyyy').format(quote.date);
        provider.rooms = List.from(quote.sections);
        provider.transportCharges = quote.transportCharges;
        provider.laborCharges = quote.laborCharges;
        provider.toggleGst(quote.isGstEnabled);

        // The company info fields should be read-only when editing
        _companyController.text = provider.companyName;
        _addressController.text = provider.address;
        _phoneController.text = provider.phone;
        _customerController.text = provider.customerName;
        _customerphoneController.text = provider.customerPhone;
        _dateController.text = provider.date;
        _transportController.text = provider.transportCharges.toString();
        _labourController.text = provider.laborCharges.toString();
        _advanceController.text =
            provider.advancePaymentPercentage?.toString() ?? '50';
      } else {
        // Regular initialization for new quotes
        _companyController.text = provider.companyName;
        _addressController.text = provider.address;
        _phoneController.text = provider.phone;
        _customerController.text = provider.customerName;
        _customerphoneController.text = provider.customerPhone;
        _dateController.text = provider.date;
        _transportController.text = provider.transportCharges.toString();
        _labourController.text = provider.laborCharges.toString();
        _advanceController.text =
            provider.advancePaymentPercentage?.toString() ?? '50';
      }

      // Setup listeners
      _companyController.addListener(() {
        if (!widget.isEditing) {
          provider.updateCompanyName(_companyController.text);
        }
      });
      _addressController.addListener(() {
        if (!widget.isEditing) {
          provider.updateAddress(_addressController.text);
        }
      });
      _phoneController.addListener(() {
        if (!widget.isEditing) {
          provider.updatePhone(_phoneController.text);
        }
      });
      _customerController.addListener(() {
        provider.updateCustomerName(_customerController.text);
      });
      _customerphoneController.addListener(() {
        provider.updateCustomerPhone(_customerphoneController.text);
      });
      _dateController.addListener(() {
        provider.updateDate(_dateController.text);
      });
      _transportController.addListener(() {
        provider.updateTransportCharges(_transportController.text);
      });
      _labourController.addListener(() {
        provider.updateLaborCharges(_labourController.text);
      });
      _advanceController.addListener(() {
        if (provider.isAdvancePaymentEnabled) {
          provider.updateAdvancePaymentPercentage(_advanceController.text);
        }
      });
    });
  }

  void _loadUserCompanies() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _companiesSubscription =
          _firestoreService.getUserCompanies(user.uid).listen((companies) {
        setState(() {
          _userCompanies = companies;
          final provider = context.read<QuoteFormProvider>();
          if (provider.selectedCompany != null) {
            final selectedCompanyId = provider.selectedCompany!.id;
            final companyExists =
                companies.any((company) => company.id == selectedCompanyId);

            if (!companyExists) {
              // If the selected company doesn't exist in the new list, reset it
              provider.clearCompanySelection();
            } else {
              // Update the selected company with the new instance from the list
              final updatedCompany = companies
                  .firstWhere((company) => company.id == selectedCompanyId);
              provider.selectCompany(updatedCompany);
            }
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _companiesSubscription?.cancel();
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
    _notesController.dispose();
    // _picker.dispose();
    super.dispose();
  }

  Widget _buildCompanySelection() {
    return Consumer<QuoteFormProvider>(
      builder: (context, provider, child) {
        return Card(
          color: kCardColor,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Company',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (_userCompanies == null)
                  const Center(child: CircularProgressIndicator())
                else if (_userCompanies!.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'No companies found. Please create a company first.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CreateCompanyScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.add_business),
                          label: const Text('Create Company'),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<Company>(
                        value: provider.selectedCompany != null &&
                                _userCompanies!.any(
                                    (c) => c.id == provider.selectedCompany!.id)
                            ? _userCompanies!.firstWhere(
                                (c) => c.id == provider.selectedCompany!.id)
                            : null,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'Choose Company',
                          hintText: 'Select a company from the list',
                          labelStyle: Theme.of(context).textTheme.bodyLarge,
                          hintStyle: Theme.of(context).textTheme.bodySmall,
                          filled: true,
                          fillColor: kInputFillColor,
                        ),
                        items: _userCompanies!.map((company) {
                          return DropdownMenuItem<Company>(
                            value: company,
                            child: Text(
                              company.name,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          );
                        }).toList(),
                        onChanged: (company) {
                          if (company != null) {
                            provider.selectCompany(company);
                            _companyController.text = company.name;
                            _addressController.text = company.address;
                            _phoneController.text = company.phone;
                          } else {
                            provider.clearCompanySelection();
                            _companyController.clear();
                            _addressController.clear();
                            _phoneController.clear();
                          }
                        },
                      ),
                      if (provider.selectedCompany != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Selected: ${provider.selectedCompany!.name}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: kAccentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      // if (provider.hasSelectedCompany && !provider.hasLogo)
                      //   Padding(
                      //     padding: const EdgeInsets.only(top: 8.0),
                      //     child: Text(
                      //       'Please upload a logo for the selected company',
                      //       style: TextStyle(
                      //         color: Colors.red[700],
                      //         fontSize: 12,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addRoom() {
    if (_roomTypeController.text.isEmpty) return;
    final provider = context.read<QuoteFormProvider>();
    provider.addRoom(QuoteRoomType(
      title: _roomTypeController.text,
      items: [],
      roomTotal: provider.roomTotal,
    ));
    _roomTypeController.clear();
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image == null) return;

      final logoFile = File(image.path);
      context.read<QuoteFormProvider>().updateLogo(logoFile);

      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Logo added successfully'),
      //       backgroundColor: Colors.green,
      //     ),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding logo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Quote _createQuote() {
    final provider = context.read<QuoteFormProvider>();
    Uint8List? logoBytes;

    if (provider.logoFile != null) {
      logoBytes = provider.logoFile!.readAsBytesSync();
    }

    final selectedCompany = provider.selectedCompany;
    final companyName = selectedCompany?.name ?? provider.companyName;
    final companyAddress = selectedCompany?.address ?? provider.address;
    final companyPhone = selectedCompany?.phone ?? provider.phone;
    final gstNumber = selectedCompany?.gstNumber ?? '';

    return Quote(
      companyName: companyName,
      address: companyAddress,
      logoBytes: logoBytes,
      phone: companyPhone,
      gstNumber: gstNumber,
      clientName: provider.customerName,
      transportCharges: provider.transportCharges,
      laborCharges: provider.laborCharges,
      date: provider.date.isNotEmpty
          ? DateFormat('dd/MM/yyyy').parse(provider.date)
          : DateTime.now(),
      sections: provider.rooms,
      isGstEnabled: provider.isGstEnabled,
      subtotal: provider.subtotal,
      cgst: provider.cgst,
      sgst: provider.sgst,
      grandTotal: provider.grandTotal,
      advancePaymentPercentage: provider.advancePaymentPercentage,
      // notes: _notesController.text,
      notes: provider.notes,
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
      final provider = context.read<QuoteFormProvider>();
      // Format the date as dd/MM/yyyy
      final formattedDate =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      _dateController.text = formattedDate;
      provider.updateDate(formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        foregroundColor: kPrimaryTextColor,
        elevation: 2,
        title: Text(
          widget.isEditing ? 'Edit Quote' : 'Create Quote',
          style: const TextStyle(color: kPrimaryTextColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview, color: kPrimaryTextColor),
            onPressed: () {
              final provider = context.read<QuoteFormProvider>();
              if (provider.selectedCompany == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a company first'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final quote = _createQuote();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuotePreviewScreen(
                    quote: quote,
                    isEditing: widget.isEditing,
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
                if (!widget.isEditing) _buildCompanySelection(),
                const SizedBox(height: 16),
                CompanyInfoSection(
                  // companyController: _companyController,
                  // addressController: _addressController,
                  // phoneController: _phoneController,
                  pickLogo: _pickLogo,
                ),
                if (widget.isEditing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: kSecondaryTextColor,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Editable Information',
                            style: TextStyle(
                              color: kSecondaryTextColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: kSecondaryTextColor,
                          ),
                        ),
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
                  color: kCardColor,
                  elevation: 2,
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
                            color: kPrimaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _roomTypeController,
                                style:
                                    const TextStyle(color: kPrimaryTextColor),
                                decoration: const InputDecoration(
                                  labelText: 'Room Type',
                                  labelStyle:
                                      TextStyle(color: kPrimaryTextColor),
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _addRoom,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAccentColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                              ),
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
                const NotesSection(),
                const SizedBox(height: 16),
                _buildSummary(),
              ],
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
          color: kCardColor,
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
                      'Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryTextColor,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'GST',
                          style: TextStyle(color: kPrimaryTextColor),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: provider.isGstEnabled,
                          onChanged: (value) => provider.toggleGst(value),
                          activeColor: kAccentColor,
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
                const Divider(color: kSecondaryTextColor),
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
            color: kPrimaryTextColor,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
