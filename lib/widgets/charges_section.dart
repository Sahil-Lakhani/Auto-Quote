import 'package:flutter/material.dart';

class ChargesSection extends StatelessWidget {
  final TextEditingController transportController;
  final TextEditingController labourController;

  const ChargesSection({
    super.key,
    required this.transportController,
    required this.labourController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Charges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: transportController,
              decoration: const InputDecoration(
                labelText: 'Transport Charges',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labourController,
              decoration: const InputDecoration(
                labelText: 'Labour Charges',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
