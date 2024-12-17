import 'package:auto_quote/models/quote_model.dart';
import 'package:auto_quote/screens/quote_preview_screen.dart';
import 'package:flutter/material.dart';

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
  final _dateController = TextEditingController();

  // bool _isDiscountEnabled = false;
  // bool _isGstEnabled = false;

  @override
  void dispose() {
    _companyController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _customerController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Quote _createQuote() {
    return Quote(
      companyName: _companyController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      clientName: _customerController.text,
      date: _dateController.text.isNotEmpty
          ? DateTime.parse(_dateController.text)
          : DateTime.now(),
      sections: [
        QuoteRoomType(
          title: 'Master Bedroom',
          items: [
            QuoteItem(
              description: 'Bed -with Storage - Surrounded Cushioning',
              areaOrQuantity: 1,
              unitPrice: 85000,
              totalPrice: 85000,
            ),
            QuoteItem(
              description: 'Wardrobe - Sliding Shutter - with Laminates',
              dimensions: "8'w x 7'h ft",
              areaOrQuantity: 56,
              unitPrice: 1850,
              totalPrice: 103600,
            ),
            QuoteItem(
              description: 'Walk-In Wardrobe - Loft Units - with Laminate',
              dimensions: "8'w x 2'h ft",
              areaOrQuantity: 16,
              unitPrice: 1150,
              totalPrice: 18400,
            ),
            QuoteItem(
              description: 'Wall Light',
              areaOrQuantity: 1,
              unitPrice: 3000,
              totalPrice: 3000,
            ),
            QuoteItem(
              description: 'Bedback Panel with duco paint and louvers',
              dimensions: "10'w x 9.5'h ft",
              areaOrQuantity: 95,
              unitPrice: 800,
              totalPrice: 76000,
            ),
          ],
        ),
        QuoteRoomType(
          title: 'Other',
          items: [
            QuoteItem(
              description: 'False Ceiling - Painting - Asian Paints',
              areaOrQuantity: 120,
              unitPrice: 25,
              totalPrice: 3000,
            ),
            QuoteItem(
              description: 'False Ceiling - Saint Gobain Brand',
              areaOrQuantity: 120,
              unitPrice: 60,
              totalPrice: 7200,
            ),
          ],
        ),
      ], 
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
      setState(() {
        _dateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quotation'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _companyController,
              decoration: InputDecoration(
                label: const Text('Company Name'),
                hintText: 'Company Name',
                prefixIcon: const Icon(Icons.business_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                label: const Text('Address'),
                hintText: 'Address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                label: const Text('Customer No.'),
                hintText: '99669 22000',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerController,
                    decoration: InputDecoration(
                      label: const Text('Customer Name'),
                      hintText: 'Enter name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      label: const Text('Date'),
                      hintText: 'Select date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  //       const SizedBox(height: 24),
  //       Container(
  //         padding: const EdgeInsets.all(16),
  //         decoration: BoxDecoration(
  //           color: Colors.orange[50],
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: TextField(
  //           decoration: InputDecoration(
  //             hintText: 'Room Name',
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             suffixIcon: IconButton(
  //               icon: const Icon(Icons.delete_outline),
  //               onPressed: () {
  //                 // Handle delete
  //               },
  //             ),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       ElevatedButton(
  //         onPressed: () {
  //           // Handle add item
  //         },
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.orange,
  //           foregroundColor: Colors.white,
  //           minimumSize: const Size(double.infinity, 48),
  //         ),
  //         child: const Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.add),
  //             SizedBox(width: 8),
  //             Text('Add Item'),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       ElevatedButton(
  //         onPressed: () {
  //           // Handle add room
  //         },
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.green,
  //           foregroundColor: Colors.white,
  //           minimumSize: const Size(double.infinity, 48),
  //         ),
  //         child: const Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.add),
  //             SizedBox(width: 8),
  //             Text('Add Room'),
  //           ],
  //         ),
  //       ),
  //       const SizedBox(height: 24),
  //       const Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text('Total'),
  //           Text('₹0'),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           const Text('Discount'),
  //           Switch(
  //             value: _isDiscountEnabled,
  //             onChanged: (value) {
  //               setState(() {
  //                 _isDiscountEnabled = value;
  //               });
  //             },
  //           ),
  //         ],
  //       ),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           const Text('GST'),
  //           Switch(
  //             value: _isGstEnabled,
  //             onChanged: (value) {
  //               setState(() {
  //                 _isGstEnabled = value;
  //               });
  //             },
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //       const Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold)),
  //           Text('₹0', style: TextStyle(fontWeight: FontWeight.bold)),
  //         ],
  //       ),
  //       const SizedBox(height: 24),
  //       _buildExpandableSection('Payment Terms'),
  //       const SizedBox(height: 16),
  //       _buildExpandableSection('Material Specification'),

  Widget _buildExpandableSection(String title) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.keyboard_arrow_down),
        onTap: () {
          // Handle expansion
        },
      ),
    );
  }
}
