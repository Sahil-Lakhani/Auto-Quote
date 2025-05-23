import 'package:flutter/material.dart';
import 'dart:async'; // Import for StreamSubscription
import '../models/product_model.dart';
import '../models/company_model.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../widgets/product_form.dart';
import '../screens/profile_screen.dart'; // Import for ProfileScreen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  // State for selected company
  String? _selectedCompanyId;
  List<Company> _userCompanies = [];
  bool _isLoadingCompanies = true;

  // Stream subscription for companies
  StreamSubscription? _companiesSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserCompanies();
  }

  // Load user's companies
  Future<void> _loadUserCompanies() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCompanies = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Cancel any existing subscription
        _companiesSubscription?.cancel();

        // Create a new subscription
        _companiesSubscription =
            _firestoreService.getUserCompanies(user.uid).listen((companies) {
          if (mounted) {
            setState(() {
              _userCompanies = companies;
              // Select the first company by default if available
              if (_selectedCompanyId == null && companies.isNotEmpty) {
                _selectedCompanyId = companies.first.id;
              }
              _isLoadingCompanies = false;
            });
          }
        }, onError: (error) {
          if (mounted) {
            setState(() {
              _isLoadingCompanies = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading companies: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingCompanies = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingCompanies = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Cancel subscription when widget is disposed
    _companiesSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showProductDialog([Product? product]) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ProductForm(
              product: product,
              companyId: _selectedCompanyId, // Pass selected company ID
              onSave: (newProduct) async {
                try {
                  if (product != null) {
                    await _firebaseService.updateProduct(
                        product.id!, newProduct);
                  } else {
                    await _firebaseService.addProduct(newProduct);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(product != null
                            ? 'Product updated successfully'
                            : 'Product added successfully'),
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
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.type == ProductType.standalone)
              Text('Price: ₹${product.price.toStringAsFixed(2)}'),
            if (product.type == ProductType.dimensionBased) ...[
              Text(
                  'Price per sqft: ₹${product.pricePerSqft!.toStringAsFixed(2)}'),
              if (product.height != null && product.width != null) ...[
                Text(
                    'Area: ${product.totalSquareFeet.toStringAsFixed(2)} sqft'),
                Text('Total Price: ₹${product.price.toStringAsFixed(2)}'),
              ],
            ],
            if (product.height != null ||
                product.width != null ||
                product.depth != null)
              Text(
                [
                  if (product.height != null) 'H: ${product.height!.formatted}',
                  if (product.width != null) 'W: ${product.width!.formatted}',
                  if (product.depth != null) 'D: ${product.depth!.formatted}',
                ].join(' × '),
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showProductDialog(product),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProduct(product),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
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
  }

  // Navigate to the profile screen properly
  void _navigateToProfile() {
    // Use named route if available
    try {
      Navigator.pushNamed(context, '/profile');
    } catch (e) {
      // Fallback to navigating by pushing a new route
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      ).then((_) => _loadUserCompanies()); // Refresh companies when returning
    }
  }

  // Build company selection dropdown
  Widget _buildCompanySelector() {
    if (_isLoadingCompanies) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userCompanies.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'No companies found',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to create or join a company before adding products',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToProfile,
                child: const Text('Go to Profile'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Company',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Company',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              value: _selectedCompanyId,
              items: _userCompanies.map((company) {
                return DropdownMenuItem(
                  value: company.id,
                  child: Text(company.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCompanyId = value;
                });
              },
            ),
          ],
        ),
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
          // Company selector UI
          _buildCompanySelector(),

          if (_selectedCompanyId != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showProductDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  StreamBuilder<List<Product>>(
                    stream: _firebaseService.getProducts(
                        companyId: _selectedCompanyId),
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
                    ? _firebaseService.searchProducts(_searchController.text,
                        companyId: _selectedCompanyId)
                    : _firebaseService.getProducts(
                        companyId: _selectedCompanyId),
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
                    itemBuilder: (context, index) =>
                        _buildProductItem(products[index]),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
