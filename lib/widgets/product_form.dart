import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final Function(Product) onSave;

  const ProductForm({
    super.key,
    this.product,
    required this.onSave,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _pricePerSqftController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Dimension controllers
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _widthFeetController = TextEditingController();
  final _widthInchesController = TextEditingController();
  final _depthFeetController = TextEditingController();
  final _depthInchesController = TextEditingController();

  ProductType _selectedType = ProductType.standalone;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _selectedType = widget.product!.type;

      if (_selectedType == ProductType.standalone) {
        _priceController.text = widget.product!.price.toString();
      } else {
        _pricePerSqftController.text = widget.product!.pricePerSqft.toString();
      }

      // Initialize dimensions if they exist
      if (widget.product!.height != null) {
        _heightFeetController.text = widget.product!.height!.feet.toString();
        _heightInchesController.text =
            widget.product!.height!.inches.toString();
      }
      if (widget.product!.width != null) {
        _widthFeetController.text = widget.product!.width!.feet.toString();
        _widthInchesController.text = widget.product!.width!.inches.toString();
      }
      if (widget.product!.depth != null) {
        _depthFeetController.text = widget.product!.depth!.feet.toString();
        _depthInchesController.text = widget.product!.depth!.inches.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _pricePerSqftController.dispose();
    _descriptionController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _widthFeetController.dispose();
    _widthInchesController.dispose();
    _depthFeetController.dispose();
    _depthInchesController.dispose();
    super.dispose();
  }

  Widget _buildDimensionFields(
      String label,
      TextEditingController feetController,
      TextEditingController inchesController,
      {bool required = false}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label),
        ),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: feetController,
            decoration: const InputDecoration(
              labelText: 'Feet',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  }
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: inchesController,
            decoration: const InputDecoration(
              labelText: 'Inches',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: required
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Allow empty for inches
                    }
                    if (int.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    final inches = int.parse(value);
                    if (inches >= 12) {
                      return 'Must be < 12';
                    }
                    return null;
                  }
                : null,
          ),
        ),
      ],
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    try {
      final product = _createProduct();
      widget.onSave(product);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Product _createProduct() {
    // Create dimensions if provided
    Dimension? height;
    Dimension? width;
    Dimension? depth;

    if (_selectedType == ProductType.dimensionBased) {
      // Height and width are required for dimension-based products
      height = Dimension(
        feet: int.parse(_heightFeetController.text),
        inches: int.parse(_heightInchesController.text.isEmpty
            ? '0'
            : _heightInchesController.text),
      );
      width = Dimension(
        feet: int.parse(_widthFeetController.text),
        inches: int.parse(_widthInchesController.text.isEmpty
            ? '0'
            : _widthInchesController.text),
      );
      print('Creating dimension-based product:');
      print('Height: ${height.formatted}');
      print('Width: ${width.formatted}');
      print('Price per sqft: ₹${_pricePerSqftController.text}');
    } else {
      print('Creating standalone product with price: ₹${_priceController.text}');
    }

    // Depth is optional for both types
    if (_depthFeetController.text.isNotEmpty &&
        _depthInchesController.text.isNotEmpty) {
      depth = Dimension(
        feet: int.parse(_depthFeetController.text),
        inches: int.parse(_depthInchesController.text),
      );
    }

    return Product(
      id: widget.product?.id,
      userId: widget.product?.userId,
      name: _nameController.text,
      type: _selectedType,
      price: _selectedType == ProductType.standalone
          ? double.parse(_priceController.text)
          : null,
      pricePerSqft: _selectedType == ProductType.dimensionBased
          ? double.parse(_pricePerSqftController.text)
          : null,
      height: height,
      width: width,
      depth: depth,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.product == null ? 'Add Product' : 'Edit Product',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ProductType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: ProductType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type == ProductType.standalone
                      ? 'Standalone'
                      : 'Dimension Based'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedType == ProductType.standalone) ...[
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ] else ...[
              TextFormField(
                controller: _pricePerSqftController,
                decoration: const InputDecoration(
                  labelText: 'Price per sq.ft',
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price per sq.ft';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDimensionFields(
                'Height',
                _heightFeetController,
                _heightInchesController,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildDimensionFields(
                'Width',
                _widthFeetController,
                _widthInchesController,
                required: true,
              ),
            ],
            const SizedBox(height: 16),
            _buildDimensionFields(
              'Depth',
              _depthFeetController,
              _depthInchesController,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _handleSave,
                  child: Text(
                      widget.product == null ? 'Add Product' : 'Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
