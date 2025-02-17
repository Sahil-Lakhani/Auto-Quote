import 'package:auto_quote/providers/quote_form_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdvancePaymentSection extends StatelessWidget {
  final TextEditingController advanceController;

  const AdvancePaymentSection({
    super.key,
    required this.advanceController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<QuoteFormProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Advance Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: advanceController,
                        decoration: const InputDecoration(
                          labelText: 'Advance Payment (%)',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          provider.updateAdvancePaymentPercentage(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (provider.advancePaymentPercentage != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Advance Amount:'),
                      Text(
                        '₹${provider.advancePaymentAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance Amount:'),
                      Text(
                        '₹${(provider.grandTotal - provider.advancePaymentAmount).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
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
