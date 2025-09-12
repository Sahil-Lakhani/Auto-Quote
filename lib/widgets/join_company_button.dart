import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/company_model.dart';
import '../theme.dart';

class JoinCompanyButton extends StatelessWidget {
  final FirestoreService firestoreService;

  const JoinCompanyButton({
    super.key,
    required this.firestoreService,
  });

  Future<void> _joinCompany(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Company'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter Invite Code',
            hintText: 'e.g., ABC123',
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

    if (code == null || code.isEmpty) return;

    try {
      final user = context.read<User?>();
      if (user == null) return;

      final result =
          await firestoreService.verifyAndJoinCompany(code, user.uid);

      if (result?['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${result?['companyName']}'),
            backgroundColor: kSuccessColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'Failed to join company'),
            backgroundColor: kWarningColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining company: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _joinCompany(context),
      icon: const Icon(Icons.group_add, size: 22),
      label: Text(
        'Join',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: kAccentColor,
      ),
    );
  }
}
