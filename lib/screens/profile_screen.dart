import 'dart:io';
import 'package:auto_quote/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  List<File> _pdfFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfs();
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
            backgroundColor: Colors.red,
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
        // Open the PDF file directly instead of the folder
        await OpenFile.open(file.path);
      } else {
        throw 'Platform not supported';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // User Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
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
                // Saved Quotations Section
                Expanded(
                  child: _pdfFiles.isEmpty
              ? const Center(child: Text('No saved quotations found'))
              : ListView.builder(
                  itemCount: _pdfFiles.length,
                  itemBuilder: (context, index) {
                    final file = _pdfFiles[index];
                    final fileName = file.path.split('/').last;
                    final fileDate = DateFormat('dd/MM/yyyy').format(
                      file.lastModifiedSync(),
                    );

                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf),
                      title: Text(fileName),
                      subtitle: Text('Created: $fileDate'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                              style:
                                                  TextStyle(color: Colors.red),
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
    );
  }
}
