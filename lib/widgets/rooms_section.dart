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

  Widget _buildItemList(QuoteRoomType room, int roomIndex) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: room.items.length,
      itemBuilder: (context, itemIndex) {
        final item = room.items[itemIndex];
        return Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                    onPressed: () => _removeItem(roomIndex, itemIndex),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.dimensions != null) Text(item.dimensions!),
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
                indent: 2,
                endIndent: 15,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddItemSection(int roomIndex) {
    return Padding(
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
                                _selectedProducts[roomIndex] = selectedProduct;
                                context.read<QuoteFormProvider>().updateItemQuantity(
                                    roomIndex,
                                    context.read<QuoteFormProvider>().itemQuantities[roomIndex] ?? 1);
                              });
                            }
                          },
                        ),
                      ),
                      if (_selectedProducts[roomIndex] != null) ...[
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: context.read<QuoteFormProvider>().itemQuantities[roomIndex] == null ||
                                      context.read<QuoteFormProvider>().itemQuantities[roomIndex]! <= 1
                                  ? null
                                  : () {
                                      context.read<QuoteFormProvider>().updateItemQuantity(
                                          roomIndex,
                                          (context.read<QuoteFormProvider>().itemQuantities[roomIndex] ?? 1) - 1);
                                    },
                            ),
                            Text(
                              '${context.read<QuoteFormProvider>().itemQuantities[roomIndex] ?? 1}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                context.read<QuoteFormProvider>().updateItemQuantity(
                                    roomIndex,
                                    (context.read<QuoteFormProvider>().itemQuantities[roomIndex] ?? 1) + 1);
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (_selectedProducts[roomIndex] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          final product = _selectedProducts[roomIndex]!;
                          final quantity = context.read<QuoteFormProvider>().itemQuantities[roomIndex] ?? 1;

                          final dimensions = [
                            if (product.height != null) 'H: ${product.height!.formatted}',
                            if (product.width != null) 'W: ${product.width!.formatted}',
                            if (product.depth != null) 'D: ${product.depth!.formatted}',
                          ].join(' × ');

                          final item = QuoteItem(
                            description: product.name,
                            dimensions: dimensions.isNotEmpty ? dimensions : null,
                            unitPrice: product.pricePerUnit,
                            quantity: quantity,
                            totalPrice: product.pricePerUnit * quantity,
                          );

                          context.read<QuoteFormProvider>().addItemToRoom(roomIndex, item);
                          setState(() {
                            _selectedProducts.remove(roomIndex);
                            _roomsInAddMode.remove(roomIndex);
                          });
                          context.read<QuoteFormProvider>().itemQuantities.remove(roomIndex);
                        },
                        child: const Text('Add'),
                      ),
                    ),
                ],
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
          children: [
            ...provider.rooms.asMap().entries.map((entry) {
              final index = entry.key;
              final room = entry.value;
              final isInAddMode = _roomsInAddMode.contains(index);

              return Card(
                margin: const EdgeInsets.only(bottom: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isInAddMode ? Icons.remove : Icons.add,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _toggleAddMode(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeRoom(index),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (room.items.isNotEmpty) _buildItemList(room, index),
                    if (isInAddMode) _buildAddItemSection(index),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}