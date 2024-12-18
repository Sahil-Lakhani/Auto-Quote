import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _widthFeetController = TextEditingController();
  final _widthInchesController = TextEditingController();
  final _depthFeetController = TextEditingController();
  final _depthInchesController = TextEditingController();
  final _otherController = TextEditingController();
  final _searchController = TextEditingController();
  
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSearching = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _widthFeetController.dispose();
    _widthInchesController.dispose();
    _depthFeetController.dispose();
    _depthInchesController.dispose();
    _otherController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDimensionFields(String label, TextEditingController feetController, TextEditingController inchesController) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: feetController,
                      decoration: const InputDecoration(
                        labelText: 'Feet',
                        suffixText: 'ft',
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: inchesController,
                      decoration: const InputDecoration(
                        labelText: 'Inches',
                        suffixText: 'in',
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 2,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final inches = int.tryParse(value);
                          if (inches != null && inches >= 12) {
                            return 'Max 11"';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddItemDialog({Product? product}) {
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.pricePerUnit.toString();
      _heightFeetController.text = product.height?.feet.toString() ?? '';
      _heightInchesController.text = product.height?.inches.toString() ?? '';
      _widthFeetController.text = product.width?.feet.toString() ?? '';
      _widthInchesController.text = product.width?.inches.toString() ?? '';
      _depthFeetController.text = product.depth?.feet.toString() ?? '';
      _depthInchesController.text = product.depth?.inches.toString() ?? '';
      _otherController.text = product.other ?? '';
    } else {
      _nameController.clear();
      _priceController.clear();
      _heightFeetController.clear();
      _heightInchesController.clear();
      _widthFeetController.clear();
      _widthInchesController.clear();
      _depthFeetController.clear();
      _depthInchesController.clear();
      _otherController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product != null ? 'Edit Item' : 'Add New Item'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter item name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price Per Unit',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildDimensionFields('Height', _heightFeetController, _heightInchesController),
                const SizedBox(height: 16),
                _buildDimensionFields('Width', _widthFeetController, _widthInchesController),
                const SizedBox(height: 16),
                _buildDimensionFields('Depth', _depthFeetController, _depthInchesController),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otherController,
                  decoration: const InputDecoration(labelText: 'Other Details'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Dimension? height, width, depth;

                if (_heightFeetController.text.isNotEmpty || _heightInchesController.text.isNotEmpty) {
                  height = Dimension(
                    feet: int.tryParse(_heightFeetController.text) ?? 0,
                    inches: int.tryParse(_heightInchesController.text) ?? 0,
                  );
                }

                if (_widthFeetController.text.isNotEmpty || _widthInchesController.text.isNotEmpty) {
                  width = Dimension(
                    feet: int.tryParse(_widthFeetController.text) ?? 0,
                    inches: int.tryParse(_widthInchesController.text) ?? 0,
                  );
                }

                if (_depthFeetController.text.isNotEmpty || _depthInchesController.text.isNotEmpty) {
                  depth = Dimension(
                    feet: int.tryParse(_depthFeetController.text) ?? 0,
                    inches: int.tryParse(_depthInchesController.text) ?? 0,
                  );
                }

                final newProduct = Product(
                  id: product?.id,
                  name: _nameController.text,
                  pricePerUnit: double.parse(_priceController.text),
                  height: height,
                  width: width,
                  depth: depth,
                  other: _otherController.text.isNotEmpty ? _otherController.text : null,
                );

                try {
                  if (product != null) {
                    await _firebaseService.updateProduct(product.id!, newProduct);
                  } else {
                    await _firebaseService.addProduct(newProduct);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(product != null ? 'Product updated successfully' : 'Product added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(product != null ? 'Update' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                StreamBuilder<List<Product>>(
                  stream: _firebaseService.getProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        'Total Items: ${snapshot.data!.length}',
                        style: TextStyle(color: Colors.grey[600]),
                      );
                    }
                    return const Text('Loading...');
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _isSearching
                  ? _firebaseService.searchProducts(_searchController.text)
                  : _firebaseService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!;
                if (products.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Price: ₹${product.pricePerUnit}'),
                            if (product.height != null || product.width != null || product.depth != null)
                              Text(
                                'Dimensions: ${[
                                  if (product.height != null) 'H: ${product.height!.formatted}',
                                  if (product.width != null) 'W: ${product.width!.formatted}',
                                  if (product.depth != null) 'D: ${product.depth!.formatted}',
                                ].join(' × ')}',
                              ),
                            if (product.other != null)
                              Text('Other: ${product.other}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddItemDialog(product: product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Product'),
                                    content: const Text('Are you sure you want to delete this product?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && product.id != null) {
                                  try {
                                    await _firebaseService.deleteProduct(product.id!);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Product deleted successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
