import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _widthFeetController = TextEditingController();
  final _widthInchesController = TextEditingController();
  final _depthFeetController = TextEditingController();
  final _depthInchesController = TextEditingController();
  final _otherController = TextEditingController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.pricePerUnit.toString();
      _heightFeetController.text =
          widget.product!.height?.feet.toString() ?? '';
      _heightInchesController.text =
          widget.product!.height?.inches.toString() ?? '';
      _widthFeetController.text = widget.product!.width?.feet.toString() ?? '';
      _widthInchesController.text =
          widget.product!.width?.inches.toString() ?? '';
      _depthFeetController.text = widget.product!.depth?.feet.toString() ?? '';
      _depthInchesController.text =
          widget.product!.depth?.inches.toString() ?? '';
      _otherController.text = widget.product!.other ?? '';
    }
  }

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
    super.dispose();
  }

  Widget _buildDimensionFields(
      String label,
      TextEditingController feetController,
      TextEditingController inchesController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: feetController,
                decoration: const InputDecoration(
                  labelText: 'Feet',
                  suffixText: 'ft',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 2,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: inchesController,
                decoration: const InputDecoration(
                  labelText: 'Inches',
                  suffixText: 'in',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 2,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
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
    );
  }

  Dimension? _getDimension(TextEditingController feetController,
      TextEditingController inchesController) {
    if (feetController.text.isNotEmpty || inchesController.text.isNotEmpty) {
      return Dimension(
        feet: int.tryParse(feetController.text) ?? 0,
        inches: int.tryParse(inchesController.text) ?? 0,
      );
    }
    return null;
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _priceController.text.isNotEmpty &&
            double.tryParse(_priceController.text) != null;
      case 1:
        return _formKey.currentState?.validate() ?? false;
      case 2:
        return true;
      default:
        return false;
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: widget.product?.id,
        name: _nameController.text,
        pricePerUnit: double.parse(_priceController.text),
        height: _getDimension(_heightFeetController, _heightInchesController),
        width: _getDimension(_widthFeetController, _widthInchesController),
        depth: _getDimension(_depthFeetController, _depthInchesController),
        other: _otherController.text.isNotEmpty ? _otherController.text : null,
      );

      widget.onSave(newProduct);
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              return 'Please enter item name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(
            labelText: 'Price',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
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
      ],
    );
  }

  Widget _buildDimensionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dimensions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildDimensionFields('Height', _heightFeetController, _heightInchesController),
        const SizedBox(height: 16),
        _buildDimensionFields('Width', _widthFeetController, _widthInchesController),
        const SizedBox(height: 16),
        _buildDimensionFields('Depth', _depthFeetController, _depthInchesController),
      ],
    );
  }

  Widget _buildAdditionalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _otherController,
          decoration: const InputDecoration(
            hintText: 'Enter any additional details about the product',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: [
                    _buildBasicInfoStep(),
                    _buildDimensionsStep(),
                    _buildAdditionalInfoStep(),
                  ][_currentStep],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_validateCurrentStep()) {
                      if (_currentStep < 2) {
                        setState(() => _currentStep++);
                      } else {
                        _handleSave();
                      }
                    }
                  },
                  child: Text(_currentStep == 2 
                    ? (widget.product != null ? 'Save' : 'Create') 
                    : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
