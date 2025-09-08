import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../models/quote_model.dart';
import '../providers/quote_form_provider.dart';
import '../services/firebase_service.dart';

class RoomsSection extends StatefulWidget {
  const RoomsSection({super.key});

  @override
  State<RoomsSection> createState() => _RoomsSectionState();
}

class _RoomsSectionState extends State<RoomsSection> {
  final FirebaseService _firebaseService = FirebaseService();
  final Map<int, Product?> _selectedProducts = {};
  final Set<int> _roomsInAddMode = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _removeRoom(int index) {
    context.read<QuoteFormProvider>().removeRoom(index);
  }

  void _removeItem(int roomIndex, int itemIndex) {
    context.read<QuoteFormProvider>().removeItemFromRoom(roomIndex, itemIndex);
  }

  double _calculateRoomTotal(List<QuoteItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Widget _buildAddItemSection(int roomIndex) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Consumer<QuoteFormProvider>(
            builder: (context, provider, child) {
              // Get the selected company ID
              final String? companyId = provider.selectedCompany?.id;

              return StreamBuilder<List<Product>>(
                // Filter products by company ID if available
                stream: companyId != null
                    ? _firebaseService.getProducts(companyId: companyId)
                    : _firebaseService.getProducts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final products = snapshot.data!;

                  if (products.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'No products found for this company.',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _toggleAddMode(roomIndex),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel'),
                              ),
                            ],
                          ),
                        )
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedProducts[roomIndex]?.id,
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
                                    _selectedProducts[roomIndex] =
                                        selectedProduct;
                                    context
                                        .read<QuoteFormProvider>()
                                        .updateItemQuantity(
                                            roomIndex,
                                            context
                                                    .read<QuoteFormProvider>()
                                                    .itemQuantities[roomIndex] ??
                                                1);
                                  });
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: context
                                            .read<QuoteFormProvider>()
                                            .itemQuantities[roomIndex] ==
                                        null ||
                                    context
                                            .read<QuoteFormProvider>()
                                            .itemQuantities[roomIndex]! <=
                                        1
                                ? null
                                : () {
                                    context
                                        .read<QuoteFormProvider>()
                                        .updateItemQuantity(
                                            roomIndex,
                                            (context
                                                            .read<
                                                                QuoteFormProvider>()
                                                            .itemQuantities[
                                                        roomIndex] ??
                                                    1) -
                                                1);
                                  },
                          ),
                          Text(
                            '${context.read<QuoteFormProvider>().itemQuantities[roomIndex] ?? 1}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              context
                                  .read<QuoteFormProvider>()
                                  .updateItemQuantity(
                                      roomIndex,
                                      (context
                                                  .read<QuoteFormProvider>()
                                                  .itemQuantities[roomIndex] ??
                                              1) +
                                          1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _selectedProducts[roomIndex] == null
                                ? null
                                : () {
                                    final product =
                                        _selectedProducts[roomIndex]!;
                                    final quantity = context
                                            .read<QuoteFormProvider>()
                                            .itemQuantities[roomIndex] ??
                                        1;

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
                                      pricePerSqft: product.pricePerSqft,
                                      quantity: quantity.toInt(),
                                      unitPrice: product.price,
                                      totalPrice: product.price * quantity,
                                      totalSqft: product.totalSquareFeet,
                                    );

                                    context
                                        .read<QuoteFormProvider>()
                                        .addItemToRoom(roomIndex, item);
                                    setState(() {
                                      _selectedProducts.remove(roomIndex);
                                      _roomsInAddMode.remove(roomIndex);
                                    });
                                    context
                                        .read<QuoteFormProvider>()
                                        .itemQuantities
                                        .remove(roomIndex);
                                  },
                            child: const Text('Add'),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: () => _toggleAddMode(roomIndex),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuoteFormProvider>(
      builder: (context, provider, child) {
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
                            padding: const EdgeInsets.only(left: 15),
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
                                        Text(
                                            'Unit Price: ₹${item.unitPrice.toStringAsFixed(2)}'),
                                        Text('Quantity: ${item.quantity}'),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 15),
                                      child: Text(
                                        '₹${item.totalPrice.toStringAsFixed(2)}',
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
                                  indent: 2,
                                  endIndent: 15,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    if (isInAddMode) _buildAddItemSection(index),
                    if (!isInAddMode)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, top: 8),
                        child: Center(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (provider.selectedCompany == null) {
                                Scrollable.of(context).position.animateTo(
                                      0,
                                      duration:
                                          const Duration(milliseconds: 500),
                                      curve: Curves.easeInOut,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a company first'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                _toggleAddMode(index);
                              }
                            },
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
            // Card(
            //   margin: const EdgeInsets.only(top: 16),
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         const Text(
            //           'Subtotal:',
            //           style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 16,
            //           ),
            //         ),
            //         Text(
            //           '₹${provider.subtotal.toStringAsFixed(2)}',
            //           style: const TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 16,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // Card(
            //   margin: const EdgeInsets.only(top: 8),
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         const Text(
            //           'CGST (9%)',
            //           style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 16,
            //           ),
            //         ),
            //         Text(
            //           '₹${provider.cgst.toStringAsFixed(2)}',
            //           style: const TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 16,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // Card(
            //   margin: const EdgeInsets.only(top: 8),
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         const Text(
            //           'SGST (9%)',
            //           style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 16,
            //           ),
            //         ),
            //         Text(
            //           '₹${provider.sgst.toStringAsFixed(2)}',
            //           style: const TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 16,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            // Card(
            //   margin: const EdgeInsets.only(top: 8),
            //   color: Colors.blue[50],
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       children: [
            //         const Text(
            //           'Grand Total:',
            //           style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 18,
            //           ),
            //         ),
            //         Text(
            //           '₹${provider.grandTotal.toStringAsFixed(2)}',
            //           style: const TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 18,
            //             color: Colors.blue,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }
}
