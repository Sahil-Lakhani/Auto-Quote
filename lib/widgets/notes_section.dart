import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quote_form_provider.dart';

class NotesSection extends StatefulWidget {
  const NotesSection({Key? key}) : super(key: key);

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  late final TextEditingController _notesController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<QuoteFormProvider>(context, listen: false);
    _notesController = TextEditingController(text: provider.notes);
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
          color: const Color(0xFFF5EBE0), // secondaryColor
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
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                    Switch(
                      value: provider.isNotesSectionEnable,
                      onChanged: (value) {
                        provider.toggleNotesSection(value);
                        if (!value) {
                          _notesController.text = '';
                        }
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
                    style: const TextStyle(color: Color(0xFF2C2C2C)),
                    decoration: InputDecoration(
                      hintText: 'Enter any additional notes here...',
                      hintStyle: const TextStyle(color: Color(0xFF4A4A4A)),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2.0,
                        ),
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
