import 'package:flutter/material.dart';
import 'package:auto_quote/theme.dart';

class TemplateSelectionScreen extends StatelessWidget {
  const TemplateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildTemplateCard(
              context,
              'Basic Template',
              'A simple and clean quotation layout',
              1,
            ),
            _buildTemplateCard(
              context,
              'Professional Template',
              'Formal design with company branding',
              2,
            ),
            _buildTemplateCard(
              context,
              'Detailed Template',
              'Comprehensive layout with detailed sections',
              3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    String title,
    String description,
    int templateId,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          // TODO: Implement template selection logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected template: $title'),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: kAccentColor.withValues(alpha: 0.2),
                child: const Center(
                  child: Icon(
                    Icons.description,
                    size: 48,
                    color: kCardColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
