import 'package:flutter/material.dart';


class CustomerInfoSection extends StatelessWidget {
  final TextEditingController customerController;
  final TextEditingController phoneController;
  final TextEditingController dateController;
  final Function(BuildContext) selectDate;

  const CustomerInfoSection({
    super.key,
    required this.customerController,
    required this.phoneController,
    required this.dateController,
    required this.selectDate,
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
              'Customer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customerController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Customer Number',
                border: OutlineInputBorder(),
                prefixText: '+91 ',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: 'Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => selectDate(context),
                ),
              ),
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }
}
