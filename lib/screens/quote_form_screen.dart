import 'package:auto_quote/models/product_model.dart';
import 'package:auto_quote/models/quote_model.dart';
import 'package:auto_quote/providers/quote_form_provider.dart';
import 'package:auto_quote/screens/quote_preview_screen.dart';
import 'package:auto_quote/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final Map<int, Product?> _selectedProducts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuoteFormProvider>();
      _companyController.text = provider.companyName;
      _addressController.text = provider.address;
      _phoneController.text = provider.phone;
      _customerController.text = provider.customerName;
      _dateController.text = provider.date;

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
      _dateController.addListener(() {
        provider.updateDate(_dateController.text);
      });
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _customerController.dispose();
    _dateController.dispose();
    _roomTypeController.dispose();
    super.dispose();
  }

  void _addRoom() {
    if (_roomTypeController.text.isEmpty) return;
    final provider = context.read<QuoteFormProvider>();
    provider.addRoom(QuoteRoomType(
        title: _roomTypeController.text,
        items: [],
      ));
      _roomTypeController.clear();
  }

  void _removeRoom(int index) {
    context.read<QuoteFormProvider>().removeRoom(index);
  }

  void _removeItem(int roomIndex, int itemIndex) {
    context.read<QuoteFormProvider>().removeItemFromRoom(roomIndex, itemIndex);
  }

  Widget _buildRoomsList() {
    return Consumer<QuoteFormProvider>(
      builder: (context, provider, child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
          children: provider.rooms.asMap().entries.map((entry) {
        final index = entry.key;
        final room = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
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
                                          _selectedProducts[index] = selectedProduct;
                                          provider.updateItemQuantity(index, provider.itemQuantities[index] ?? 1);
                                    });
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                              onPressed: provider.itemQuantities[index] == null ||
                                      provider.itemQuantities[index]! <= 1
                              ? null
                              : () {
                                      provider.updateItemQuantity(
                                          index, (provider.itemQuantities[index] ?? 1) - 1);
                                },
                        ),
                        Text(
                              '${provider.itemQuantities[index] ?? 1}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                                provider.updateItemQuantity(
                                    index, (provider.itemQuantities[index] ?? 1) + 1);
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: _selectedProducts[index] == null
                            ? null
                            : () {
                                final product = _selectedProducts[index]!;
                                    final quantity = provider.itemQuantities[index] ?? 1;

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

                                    provider.addItemToRoom(index, item);
                                setState(() {
                                  _selectedProducts.remove(index);
                                });
                                    provider.itemQuantities.remove(index);
                              },
                        child: const Text('Add Item'),
                      ),
                    ),
                  ],
                ),
              ),
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
                                    icon: const Icon(Icons.delete, color: Colors.red),
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
                              Divider(
                                color: Colors.grey[500],
                                indent: 02,
                                endIndent: 15,
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
      },
    );
  }

  Quote _createQuote() {
    final provider = context.read<QuoteFormProvider>();
    return Quote(
      companyName: provider.companyName,
      address: provider.address,
      phone: provider.phone,
      clientName: provider.customerName,
      date: provider.date.isNotEmpty
          ? DateTime.parse(provider.date)
          : DateTime.now(),
      sections: provider.rooms,
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
        final provider = context.read<QuoteFormProvider>();
        provider.updateDate(picked.toIso8601String().split('T')[0]);
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
