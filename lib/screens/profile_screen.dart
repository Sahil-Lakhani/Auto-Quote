import 'dart:async';
import 'dart:io';

import 'package:auto_quote/screens/create_company_screen.dart';
import 'package:auto_quote/screens/user_comapny_list.dart';
import 'package:auto_quote/services/firebase_auth_service.dart';
import 'package:auto_quote/services/firestore_service.dart';
import 'package:auto_quote/models/company_model.dart';
import 'package:auto_quote/widgets/company_invite_code.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:auto_quote/theme.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_quote/models/quote_model.dart';
import 'package:auto_quote/screens/quote_edit_screen.dart';
import '../widgets/join_company_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  List<File> _pdfFiles = [];
  bool _isLoading = true;
  List<Company>? _userCompanies;
  StreamSubscription? _companiesSubscription;

  @override
  void initState() {
    super.initState();
    _loadPdfs();
    _subscribeToUserCompanies();
  }

  @override
  void dispose() {
    _companiesSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToUserCompanies() {
    final user = context.read<User?>();
    if (user != null) {
      _companiesSubscription =
          _firestoreService.getUserCompanies(user.uid).listen((companies) {
        setState(() {
          _userCompanies = companies;
        });
      });
    }
  }

  Future<void> _loadPdfs() async {
    setState(() => _isLoading = true);
    try {
      final pdfs = await _storageService.getSavedPdfs();
      setState(() => _pdfFiles = pdfs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDFs: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = context.read<AuthService>();
    try {
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: kWarningColor,
          ),
        );
      }
    }
  }

  Future<void> _deletePdf(File file) async {
    try {
      await _storageService.deletePdf(file);
      await _loadPdfs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting PDF: $e')),
        );
      }
    }
  }

  Future<void> _openFileLocation(File file) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await OpenFile.open(file.path);
      } else {
        throw 'Platform not supported';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: kWarningColor,
          ),
        );
      }
    }
  }

  void _navigateToCreateCompany() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCompanyScreen(),
      ),
    );
  }

  void _navigateToJoinCompany() {
    print('Join company button clicked');
    // Will implement this later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Join company feature coming soon')),
    );
  }

  void _navigateToCompanyList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CompanyListScreen(),
      ),
    );
  }

    Future<void> _joinCompany(BuildContext context) async {
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

  Future<void> _editQuotation(File file) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Extract the filename from the path for more reliable matching
      final fileName = file.path.split('/').last;

      // Get quotation data from Firebase with a more flexible query
      final querySnapshot = await FirebaseFirestore.instance
          .collection('quotations')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No quotations found for this user');
      }

      // Find the document where pdfPath ends with the filename
      final quotationDoc = querySnapshot.docs.firstWhere(
        (doc) => doc.data()['pdfPath'].toString().endsWith(fileName),
        orElse: () => throw Exception('Quotation not found: $fileName'),
      );

      final quotationData = quotationDoc.data();

      // Create a Quote object from the data
      final List<QuoteRoomType> sections = [];
      for (final sectionData in quotationData['sections'] as List<dynamic>) {
        final List<QuoteItem> items = [];
        for (final itemData in sectionData['items'] as List<dynamic>) {
          items.add(QuoteItem(
            description: itemData['description'] as String,
            dimensions: itemData['dimensions'] as String?,
            quantity: itemData['quantity'] as int?,
            unitPrice: (itemData['unitPrice'] as num).toDouble(),
            totalPrice: (itemData['totalPrice'] as num).toDouble(),
          ));
        }
        sections.add(QuoteRoomType(
          title: sectionData['title'] as String,
          items: items,
          roomTotal: (sectionData['roomTotal'] as num).toDouble(),
        ));
      }

      final quote = Quote(
        companyName: quotationData['companyName'] as String,
        address: quotationData['address'] ?? '',
        gstNumber: quotationData['gstNumber'] ?? '-',
        phone: quotationData['phone'] ?? '',
        clientName: quotationData['clientName'] as String,
        date: (quotationData['date'] as Timestamp).toDate(),
        sections: sections,
        transportCharges: quotationData['transportCharges'] as int,
        laborCharges: quotationData['laborCharges'] as int,
        subtotal: (quotationData['subtotal'] as num).toDouble(),
        isGstEnabled: quotationData['isGstEnabled'] as bool,
        cgst: (quotationData['cgst'] as num).toDouble(),
        sgst: (quotationData['sgst'] as num).toDouble(),
        grandTotal: (quotationData['grandTotal'] as num).toDouble(),
        advancePaymentPercentage:
            quotationData['advancePaymentPercentage'] != null
                ? (quotationData['advancePaymentPercentage'] as num).toInt()
                : null,
      );

      // Navigate to the edit screen with the quotation document ID
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuoteEditScreen(
              quoteId: quotationDoc.id,
              quotationFile: file,
              existingQuote: quote,
            ),
          ),
        ).then((_) => _loadPdfs()); // Refresh PDFs when returning
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quotation: $e'),
            backgroundColor: kWarningColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleLogout(context);
                    },
                    child: const Text('Logout',
                        style: TextStyle(color: kWarningColor)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? 'User',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Company Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Companies',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            TextButton(
                              onPressed: _navigateToCompanyList,
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: kAccentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // const GenerateInviteCodeScreen(company: widget.company),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _navigateToCreateCompany,
                                icon: const Icon(Icons.add_business, size: 22,),
                                label: const Text('Create',
                                    style: TextStyle(fontSize: 18)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kAccentColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: JoinCompanyButton(
                                  firestoreService: _firestoreService),
                            ),
                          ],
                        ),

                        // const SizedBox(height: 16),
                        // Display user's companies
                        // if (_userCompanies == null)
                        //   const Center(child: CircularProgressIndicator())
                        // else if (_userCompanies!.isEmpty)
                        //   const Center(
                        //     child: Text(
                        //       'You are not a member of any company',
                        //       style: TextStyle(fontStyle: FontStyle.italic),
                        //     ),
                        //   )
                        // else
                        // SizedBox(
                        //   height: 120,
                        //   child: ListView.builder(
                        //     scrollDirection: Axis.horizontal,
                        //     itemCount: _userCompanies!.length,
                        //     itemBuilder: (context, index) {
                        //       final company = _userCompanies![index];
                        //       return Card(
                        //         margin: const EdgeInsets.only(right: 12),
                        //         child: InkWell(
                        //           onTap: () {
                        //             // Navigate to company details
                        //           },
                        //           child: Container(
                        //             width: 150,
                        //             padding: const EdgeInsets.all(12),
                        //             child: Column(
                        //               crossAxisAlignment:
                        //                   CrossAxisAlignment.start,
                        //               children: [
                        //                 Text(
                        //                   company.name,
                        //                   style: const TextStyle(
                        //                     fontWeight: FontWeight.bold,
                        //                     fontSize: 16,
                        //                   ),
                        //                   maxLines: 1,
                        //                   overflow: TextOverflow.ellipsis,
                        //                 ),
                        //                 const SizedBox(height: 8),
                        //                 Text(
                        //                   company.address,
                        //                   maxLines: 1,
                        //                   overflow: TextOverflow.ellipsis,
                        //                 ),
                        //                 const Spacer(),
                        //                 Text(
                        //                   '${company.memberIds.length} members',
                        //                   style: const TextStyle(
                        //                     color: Colors.grey,
                        //                     fontSize: 12,
                        //                   ),
                        //                 ),
                        //               ],
                        //             ),
                        //           ),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Saved Quotations Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Saved Quotations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  SizedBox(
                    height: 400,
                    child: _pdfFiles.isEmpty
                        ? const Center(child: Text('No saved quotations found'))
                        : ListView.builder(
                            itemCount: _pdfFiles.length,
                            shrinkWrap: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final file = _pdfFiles[index];
                              final fileName = file.path.split('/').last;
                              final fileDate = DateFormat('dd/MM/yyyy').format(
                                file.lastModifiedSync(),
                              );

                              return ListTile(
                                leading: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 32,
                                ),
                                title: Text(fileName,
                                    style: const TextStyle(fontSize: 14)),
                                subtitle: Text('Created: $fileDate'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editQuotation(file),
                                      tooltip: 'Edit Quotation',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      onPressed: () =>
                                          _storageService.sharePdf(file),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Quote'),
                                          content: const Text(
                                            'Are you sure you want to delete this quote?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deletePdf(file);
                                              },
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _openFileLocation(file),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
