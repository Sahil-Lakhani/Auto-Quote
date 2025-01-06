import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import 'quote_preview_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading PDFs: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePdf(File file) async {
    try {
      await _storageService.deletePdf(file);
      await _loadPdfs(); // Refresh the list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved quotations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfFiles.isEmpty
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
                            onPressed: () => _storageService.sharePdf(file),
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
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deletePdf(file);
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        print("Tapped on ${file.path}");
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => QuotePreviewScreen(
                        //       quote: file,
                        //     ),
                        //   ),
                        // );
                      },
                    );
                  },
                ),
    );
  }
}
