import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quote_form_provider.dart';
import '../theme.dart'; // import your theme colors

class NotesSection extends StatefulWidget {
  const NotesSection({super.key});

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<QuoteFormProvider>(context, listen: false);

    // Ensure controller has provider’s value only on first load
    if (_notesController.text.isEmpty && provider.notes.isNotEmpty) {
      _notesController.text = provider.notes;
    }

    _notesController.removeListener(_onNotesChanged);
    _notesController.addListener(_onNotesChanged);
  }

  void _onNotesChanged() {
    final provider = Provider.of<QuoteFormProvider>(context, listen: false);
    if (_notesController.text != provider.notes) {
      provider.updateNotes(_notesController.text);
    }
  }

  @override
  void dispose() {
    _notesController.removeListener(_onNotesChanged);
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuoteFormProvider>(
      builder: (context, provider, child) {
        return Card(
          color: kCardColor, // from theme.dart
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header row with title + switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Switch(
                      value: provider.isNotesSectionEnable,
                      onChanged: (value) {
                        provider.toggleNotesSection(value);
                      },
                    ),
                  ],
                ),

                /// Show text field only if enabled
                if (provider.isNotesSectionEnable) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Enter any additional notes here...',
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                      filled: true,
                      fillColor: kInputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: kSecondaryTextColor.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
