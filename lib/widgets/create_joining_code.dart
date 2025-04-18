import 'package:auto_quote/models/company_model.dart';
import 'package:auto_quote/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GenerateInviteCodeScreen extends StatefulWidget {
  final Company company;

  const GenerateInviteCodeScreen({super.key, required this.company});

  @override
  _GenerateInviteCodeScreenState createState() => _GenerateInviteCodeScreenState();
}

class _GenerateInviteCodeScreenState extends State<GenerateInviteCodeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _inviteCode;
  bool _isLoading = false;

  Future<void> _generateCode() async {
    setState(() => _isLoading = true);
    try {
      final code =
          await _firestoreService.generateCompanyInviteCode(widget.company.id);
      setState(() => _inviteCode = code);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating code: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Invite Code')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_inviteCode != null) ...[
                Text(
                  _inviteCode!,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Share this code with others to let them join ${widget.company.name}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Code'),
                ),
              ],
              if (_inviteCode == null)
                ElevatedButton(
                  onPressed: _isLoading ? null : _generateCode,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Generate Invite Code'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
