import 'package:auto_quote/models/company_model.dart';
import 'package:auto_quote/screens/create_company_screen.dart';
import 'package:auto_quote/services/firestore_service.dart';
import 'package:auto_quote/widgets/compact_invite_code.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Stream<List<Company>> _companiesStream;

  @override
  void initState() {
    super.initState();
    final user = context.read<User?>();
    if (user != null) {
      _companiesStream = _firestoreService.getUserCompanies(user.uid);
    }
  }

  Future<void> _joinCompany(BuildContext context) async {
    // Show a dialog to enter company ID
    final TextEditingController controller = TextEditingController();

    final companyId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Company'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter Company ID',
            hintText: 'e.g., acbd1234',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (companyId == null || companyId.isEmpty) return;

    // Print statement as requested
    print('Join company button clicked with ID: $companyId');

    try {
      final company = await _firestoreService.getCompanyById(companyId);
      if (company == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company not found')),
        );
        return;
      }

      final user = context.read<User?>();
      if (user == null) return;

      await _firestoreService.joinCompany(companyId, user.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined ${company.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining company: $e')),
      );
    }
  }

  Future<void> _editCompany(BuildContext context, Company company) async {
    final user = context.read<User?>();
    if (user == null || user.uid != company.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the company owner can edit')),
      );
      return;
    }

    final nameController = TextEditingController(text: company.name);
    final addressController = TextEditingController(text: company.address);
    final phoneController = TextEditingController(text: company.phone);
    final gstNumberController =
        TextEditingController(text: company.gstNumber ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Company'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: gstNumberController,
                decoration:
                    const InputDecoration(labelText: 'GST Number (Optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _firestoreService.updateCompany(
        companyId: company.id,
        name: nameController.text.trim(),
        address: addressController.text.trim(),
        phone: phoneController.text.trim(),
        gstNumber: gstNumberController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating company: $e')),
        );
      }
    }
  }

  Future<void> _deleteCompany(BuildContext context, Company company) async {
    final user = context.read<User?>();
    if (user == null || user.uid != company.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the company owner can delete')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text(
            'Are you sure you want to delete ${company.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _firestoreService.deleteCompany(company.id);

      // TODO: When a company is deleted, we need to update all members' company lists
      // for (final memberId in company.memberIds) {
      //   await _firestoreService.leaveCompany(company.id, memberId);
      // }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting company: $e')),
        );
      }
    }
  }

  Future<void> _leaveCompany(BuildContext context, Company company) async {
    final user = context.read<User?>();
    if (user == null) return;

    // Owner cannot leave their own company, they must delete it
    if (user.uid == company.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'As owner, you cannot leave your company. You must delete it instead.')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Company'),
        content: Text('Are you sure you want to leave ${company.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _firestoreService.leaveCompany(company.id, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have left ${company.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving company: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('You must be logged in to view companies'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Companies'),
      ),
      body: StreamBuilder<List<Company>>(
        stream: _companiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final companies = snapshot.data ?? [];

          if (companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'You are not a member of any company',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateCompanyScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_business),
                    label: const Text('Create Company'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateCompanyScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_business),
                        label: const Text('Create Company'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _joinCompany(context),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join Company'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    final isOwner = company.ownerId == user.uid;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        // vertical: 8.0,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              company.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Address: ${company.address}'),
                                Text('Phone: ${company.phone}'),
                                if (company.gstNumber != null &&
                                    company.gstNumber.isNotEmpty)
                                  Text('GST: ${company.gstNumber}'),
                                Text(
                                  'Created: ${DateFormat('MMM d, yyyy').format(company.createdAt)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Members: ${company.memberIds.length}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: isOwner
                                ? const Chip(
                                    label: Text('Owner'),
                                    backgroundColor: Colors.green,
                                    labelStyle: TextStyle(color: Colors.white),
                                  )
                                : const Chip(
                                    label: Text('Member'),
                                    backgroundColor: Colors.blue,
                                    labelStyle: TextStyle(color: Colors.white),
                                  ),
                            isThreeLine: true,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          if (isOwner)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16.0, right: 16.0, bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () =>
                                            _editCompany(context, company),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Edit'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.blue,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          minimumSize: const Size(0, 32),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _deleteCompany(context, company),
                                        icon:
                                            const Icon(Icons.delete, size: 16),
                                        label: const Text('Delete'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          minimumSize: const Size(0, 32),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // if (isOwner)
                                    CompanyInviteCodeWidget(company: company),
                                ],
                              ),
                            )
                          else // Members can leave
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16.0, right: 16.0, bottom: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        _leaveCompany(context, company),
                                    icon:
                                        const Icon(Icons.exit_to_app, size: 16),
                                    label: const Text('Leave Company'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      minimumSize: const Size(0, 32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
