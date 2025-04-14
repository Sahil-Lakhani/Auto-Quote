import 'dart:typed_data';
import 'package:auto_quote/models/quote_model.dart';
import 'package:auto_quote/providers/quote_form_provider.dart';
import 'package:auto_quote/screens/quote_preview_screen.dart';
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

class QuoteFormScreen extends StatefulWidget {
  const QuoteFormScreen({super.key});

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

  // final FirebaseService _firebaseService = FirebaseService();
  // final Map<int, Product?> _selectedProducts = {};
  // final Set<int> _roomsInAddMode = {};
  final ImagePicker _picker = ImagePicker();
  // File? _logoFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuoteFormProvider>();
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

      // Setup listeners
      _companyController.addListener(() {
        provider.updateCompanyName(_companyController.text);
      });
      _addressController.addListener(() {
        provider.updateAddress(_addressController.text);
      });
      _phoneController.addListener(() {
        provider.updatePhone(_phoneController.text);
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
    super.dispose();
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
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

  Widget _buildLogoPreview() {
    return Consumer<QuoteFormProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 128,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: provider.logoFile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        provider.logoFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          border: Border.all(color: Colors.white, width: 1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            provider.removeLogo();
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: TextButton.icon(
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Logo'),
                  ),
                ),
        );
      },
    );
  }

  Quote _createQuote() {
    final provider = context.read<QuoteFormProvider>();
    Uint8List? logoBytes;

    if (provider.logoFile != null) {
      logoBytes = provider.logoFile!.readAsBytesSync();
    }

    return Quote(
      companyName: provider.companyName,
      address: provider.address,
      logoBytes: logoBytes,
      phone: provider.phone,
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
      appBar: AppBar(
        title: const Text('Create Quote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () {
              final quote = _createQuote();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuotePreviewScreen(quote: quote),
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
                CompanyInfoSection(
                  companyController: _companyController,
                  addressController: _addressController,
                  phoneController: _phoneController,
                  pickLogo: _pickLogo,
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
}
