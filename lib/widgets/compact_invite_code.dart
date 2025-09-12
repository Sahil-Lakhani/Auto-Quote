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
      width: 100, // Fixed width to prevent overflow
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHigh
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              inviteCode,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            visualDensity: VisualDensity.compact,
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

  @override
  void initState() {
    super.initState();
    // Use existing invite code if available
    if (widget.company.inviteCode.isNotEmpty) {
      _inviteCode = widget.company.inviteCode;
    }
  }

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
      mainAxisSize: MainAxisSize.min,
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
          )
        else
          TextButton.icon(
            onPressed: _isLoading ? null : _generateCode,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add, size: 16),
            label: const Text('Generate Code'),
            style: TextButton.styleFrom(
              // padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              minimumSize: const Size(0, 32),
            ),
          ),
        if (_inviteCode != null)
          SizedBox(
            // width: 55,
            height: 32,
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync, size: 16),
              onPressed: _isLoading ? null : _generateCode,
              tooltip: 'Regenerate Code',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}
