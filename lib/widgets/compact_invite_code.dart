import 'package:auto_quote/models/company_model.dart';
import 'package:auto_quote/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompactInviteCodeWidget extends StatelessWidget {
  final String inviteCode;
  final VoidCallback onCopy;

  const CompactInviteCodeWidget({
    super.key,
    required this.inviteCode,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(
              alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            inviteCode,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

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
    return Row(
      children: [
        if (_inviteCode != null)
          CompactInviteCodeWidget(
            inviteCode: _inviteCode!,
            onCopy: () {
              Clipboard.setData(ClipboardData(text: _inviteCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
          ),
        TextButton.icon(
          onPressed: _isLoading ? null : _generateCode,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync, size: 16),
          label: Text(_inviteCode == null ? 'Generate Code' : ''),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6),
            minimumSize: const Size(0, 32),
          ),
        ),
      ],
    );
  }
}
