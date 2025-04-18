// In company_invite_code.dart

import 'package:auto_quote/models/company_model.dart';
import 'package:auto_quote/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CompanyInviteCodeWidget extends StatefulWidget {
  final Company company;

  const CompanyInviteCodeWidget({
    super.key,
    required this.company,
  });

  @override
  State<CompanyInviteCodeWidget> createState() =>
      _CompanyInviteCodeWidgetState();
}

class _CompanyInviteCodeWidgetState extends State<CompanyInviteCodeWidget> {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating code: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.company.ownerId != context.read<User?>()?.uid) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_inviteCode != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _inviteCode!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        TextButton.icon(
          onPressed: _isLoading ? null : _generateCode,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, size: 18),
          label: Text(_inviteCode == null ? 'Generate Code' : ''),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: const Size(0, 32),
          ),
        ),
      ],
    );
  }
}
