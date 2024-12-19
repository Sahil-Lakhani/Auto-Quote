import 'package:auto_quote/models/product_model.dart';
import 'package:auto_quote/models/quote_model.dart';
import 'package:auto_quote/screens/quote_preview_screen.dart';
import 'package:auto_quote/services/firebase_service.dart';
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
  final _roomTypeController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();
  final List<QuoteRoomType> _rooms = [];
  final Map<int, Product?> _selectedProducts = {};
  final Map<int, int> _itemQuantities = {};
  // bool _isDiscountEnabled = false;
  // bool _isGstEnabled = false;

  @override
  void dispose() {
    _companyController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _customerController.dispose();
    _dateController.dispose();
    _roomTypeController.dispose();
    // _selectedProducts.clear();
    // _itemQuantities.clear();
    super.dispose();
  }

  void _addRoom() {
    if (_roomTypeController.text.isEmpty) return;
    setState(() {
      _rooms.add(QuoteRoomType(
        title: _roomTypeController.text,
        items: [],
      ));
      _roomTypeController.clear();
    });
  }

  void _removeRoom(int index) {
    setState(() {
      _rooms.removeAt(index);
    });
  }

  void _removeItem(int roomIndex, int itemIndex) {
    setState(() {
      _rooms[roomIndex].items.removeAt(itemIndex);
    });
  }

  Widget _buildRoomsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: _rooms.asMap().entries.map((entry) {
        final index = entry.key;
        final room = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Room Title and Delete Button
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      room.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeRoom(index),
                    ),
                  ],
                ),
              ),

              // Item Selection Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<List<Product>>(
                            stream: _firebaseService.getProducts(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const CircularProgressIndicator();
                              }

                              final products = snapshot.data!;
                              return DropdownButtonFormField<String>(
                                value: _selectedProducts[index]?.id,
                                decoration: const InputDecoration(
                                  labelText: 'Select Item',
                                  border: OutlineInputBorder(),
                                ),
                                items: products.map((product) {
                                  return DropdownMenuItem(
                                    value: product.id,
                                    child: Text(product.name),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    final selectedProduct = products.firstWhere(
                                      (product) => product.id == value,
                                    );
                                    setState(() {
                                      _selectedProducts[index] =
                                          selectedProduct;
                                      if (_itemQuantities[index] == null) {
                                        _itemQuantities[index] = 1;
                                      }
                                    });
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _itemQuantities[index] == null ||
                                  _itemQuantities[index]! <= 1
                              ? null
                              : () {
                                  setState(() {
                                    _itemQuantities[index] =
                                        _itemQuantities[index]! - 1;
                                  });
                                },
                        ),
                        Text(
                          '${_itemQuantities[index] ?? 1}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              _itemQuantities[index] =
                                  (_itemQuantities[index] ?? 1) + 1;
                            });
                          },
                        ),
                      ],
                    ),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: _selectedProducts[index] == null
                            ? null
                            : () {
                                final product = _selectedProducts[index]!;
                                final quantity = _itemQuantities[index] ?? 1;

                                final item = QuoteItem(
                                  description: product.name,
                                  dimensions: [
                                    if (product.height != null)
                                      'H: ${product.height!.formatted}',
                                    if (product.width != null)
                                      'W: ${product.width!.formatted}',
                                    if (product.depth != null)
                                      'D: ${product.depth!.formatted}',
                                  ].join(' × '),
                                  areaOrQuantity: quantity.toDouble(),
                                  unitPrice: product.pricePerUnit,
                                  totalPrice: product.pricePerUnit * quantity,
                                );

                                setState(() {
                                  _rooms[index].items.add(item);
                                  _selectedProducts.remove(index);
                                  _itemQuantities.remove(index);
                                });
                              },
                        child: const Text('Add Item'),
                      ),
                    ),
                  ],
                ),
              ),

              // Added Items List
              if (room.items.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: room.items.length,
                  itemBuilder: (context, itemIndex) {
                    final item = room.items[itemIndex];
                    return Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Divider(
                            color: Colors.grey[500],
                            indent: 02,
                            endIndent: 15,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeItem(index, itemIndex),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  if (item.dimensions != null)
                                    Text(item.dimensions!),
                                  Text('Price: ₹${item.unitPrice}'),
                                  Text('Quantity: ${item.areaOrQuantity}'),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 15),
                                child: Text(
                                  '₹${item.totalPrice}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }).toList(),
    );
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
      sections: _rooms,
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
            const SizedBox(height: 16),
            const Text(
              'Rooms',
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
                    decoration: InputDecoration(
                      label: const Text('Room Type'),
                      hintText: 'Master Bedroom, Living Room',
                      prefixIcon: const Icon(Icons.room_preferences),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                ),
                  ),
            ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addRoom,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Room'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRoomsList(),
          ],
        ),
      ),
    );
  }

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
