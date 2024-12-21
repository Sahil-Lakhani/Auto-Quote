import 'package:auto_quote/models/product_model.dart';
import 'package:auto_quote/models/quote_model.dart';
import 'package:auto_quote/providers/quote_form_provider.dart';
import 'package:auto_quote/screens/quote_preview_screen.dart';
import 'package:auto_quote/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  final _transportController = TextEditingController();
  final _labourController = TextEditingController();

  final FirebaseService _firebaseService = FirebaseService();
  final Map<int, Product?> _selectedProducts = {};
  final Set<int> _roomsInAddMode = {};
  final ImagePicker _picker = ImagePicker();
  File? _logoFile;

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
      _transportController.text = provider.transportCharges.toString();
      _labourController.text = provider.laborCharges.toString();

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
      _transportController.addListener(() {
        provider.updateTransportCharges(_transportController.text);
      });
      _labourController.addListener(() {
        provider.updateLaborCharges(_labourController.text);
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

  void _removeRoom(int index) {
    context.read<QuoteFormProvider>().removeRoom(index);
  }

  void _removeItem(int roomIndex, int itemIndex) {
    context.read<QuoteFormProvider>().removeItemFromRoom(roomIndex, itemIndex);
  }

  double _calculateRoomTotal(List<QuoteItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double _calculateGrandTotal(List<QuoteRoomType> rooms) {
    return rooms.fold(
        0.0, (sum, room) => sum + _calculateRoomTotal(room.items));
  }

  void _toggleAddMode(int roomIndex) {
    setState(() {
      if (_roomsInAddMode.contains(roomIndex)) {
        _roomsInAddMode.remove(roomIndex);
        _selectedProducts.remove(roomIndex);
      } else {
        _roomsInAddMode.add(roomIndex);
      }
    });
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Limit image size for preview
        maxHeight: 512,
      );

      if (image == null) return;

      setState(() {
        _logoFile = File(image.path);
      });

      // Show success message
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
    return Container(
      height: 128,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _logoFile != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _logoFile!,
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
                      constraints:
                          const BoxConstraints(), 
                      onPressed: () {
                        setState(() {
                          _logoFile = null;
                        });
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
  }

  Widget _buildRoomsList() {
    return Consumer<QuoteFormProvider>(
      builder: (context, provider, child) {
        final grandTotal = _calculateGrandTotal(provider.rooms);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ...provider.rooms.asMap().entries.map((entry) {
        final index = entry.key;
        final room = entry.value;
              final roomTotal = _calculateRoomTotal(room.items);
              final isInAddMode = _roomsInAddMode.contains(index);

        return Card(
                margin: const EdgeInsets.only(bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                      padding: const EdgeInsets.all(15),
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
                    Divider(
                      color: Colors.grey[300],
                      thickness: 1,
                      height: 1,
                    ),
                    if (room.items.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: room.items.length,
                  itemBuilder: (context, itemIndex) {
                    final item = room.items[itemIndex];
                    return Padding(
                            padding: const EdgeInsets.only(
                              left: 15,
                            ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _removeItem(index, itemIndex),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                children: [
                                  if (item.dimensions != null)
                                    Text(item.dimensions!),
                                  Text('Price: ₹${item.unitPrice}'),
                                      Text('Quantity: ${item.quantity}'),
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
                                  height: 25,
                                color: Colors.grey[500],
                                indent: 02,
                                endIndent: 15,
                              ),
                        ],
                      ),
                    );
                  },
                ),
                    if (isInAddMode)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            StreamBuilder<List<Product>>(
                              stream: _firebaseService.getProducts(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const CircularProgressIndicator();
                                }

                                final products = snapshot.data!;
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: StreamBuilder<List<Product>>(
                                            stream:
                                                _firebaseService.getProducts(),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return const CircularProgressIndicator();
                                              }

                                              final products = snapshot.data!;
                                              return DropdownButtonFormField<
                                                  String>(
                                                value: _selectedProducts[index]
                                                    ?.id,
                                                decoration:
                                                    const InputDecoration(
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
                                                    final selectedProduct =
                                                        products.firstWhere(
                                                      (product) =>
                                                          product.id == value,
                                                    );
                                                    setState(() {
                                                      _selectedProducts[index] =
                                                          selectedProduct;
                                                      provider.updateItemQuantity(
                                                          index,
                                                          provider.itemQuantities[
                                                                  index] ??
                                                              1);
                                                    });
                                                  }
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed:
                                              provider.itemQuantities[index] ==
                                                          null ||
                                                      provider.itemQuantities[
                                                              index]! <=
                                                          1
                                                  ? null
                                                  : () {
                                                      provider.updateItemQuantity(
                                                          index,
                                                          (provider.itemQuantities[
                                                                      index] ??
                                                                  1) -
                                                              1);
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
                                                index,
                                                (provider.itemQuantities[
                                                            index] ??
                                                        1) +
                                                    1);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: _selectedProducts[index] ==
                                                  null
                                              ? null
                                              : () {
                                                  final product =
                                                      _selectedProducts[index]!;
                                                  final quantity =
                                                      provider.itemQuantities[
                                                              index] ??
                                                          1;

                                                  final item = QuoteItem(
                                                    description: product.name,
                                                    dimensions: [
                                                      if (product.height !=
                                                          null)
                                                        'H: ${product.height!.formatted}',
                                                      if (product.width != null)
                                                        'W: ${product.width!.formatted}',
                                                      if (product.depth != null)
                                                        'D: ${product.depth!.formatted}',
                                                    ].join(' × '),
                                                    quantity: quantity.toInt(),
                                                    unitPrice:
                                                        product.pricePerUnit,
                                                    totalPrice:
                                                        product.pricePerUnit *
                                                            quantity,
                                                  );

                                                  provider.addItemToRoom(
                                                      index, item);
                                                  setState(() {
                                                    _selectedProducts
                                                        .remove(index);
                                                    _roomsInAddMode
                                                        .remove(index);
                                                  });
                                                  provider.itemQuantities
                                                      .remove(index);
                                                },
                                          child: const Text('Add'),
                                        ),
                                        const SizedBox(width: 16),
                                        OutlinedButton(
                                          onPressed: () =>
                                              _toggleAddMode(index),
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    if (!isInAddMode)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 8),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _toggleAddMode(index),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ),
                      ),
                    if (room.items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Room Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '₹${roomTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
            ],
          ),
        );
      }).toList(),
              Card(
                margin: const EdgeInsets.only(top: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${provider.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CGST (9%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${provider.cgst.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SGST (9%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${provider.sgst.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 8),
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Grand Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                      '₹${provider.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
      transportCharges: provider.transportCharges,
      laborCharges: provider.laborCharges,
      date: provider.date.isNotEmpty
          ? DateTime.parse(provider.date)
          : DateTime.now(),
      sections: provider.rooms,
      subtotal: provider.subtotal,
      cgst: provider.cgst,
      sgst: provider.sgst,
      grandTotal: provider.grandTotal,
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _transportController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: const Text('Transport Charges'),
                      hintText: '₹0',
                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _labourController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: const Text('Labour Charges'),
                      hintText: '₹0',
                      prefixIcon: const Icon(Icons.engineering_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
