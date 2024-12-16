import 'package:flutter/material.dart';
import 'models/quote_model.dart';
import 'screens/quote_preview_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Quote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  Quote _getSampleQuote() {
    return Quote(
      companyName: 'Design Que',
      address: 'address xyz',
      phone: '99669 22000',
      clientName: 'ravi varma',
      date: DateTime(2024, 10, 30),
      sections: [
        QuoteSection(
          title: 'Master Bedroom',
          items: [
            QuoteItem(
              description: 'Bed -with Storage - Surrounded Cushioning',
              areaOrQuantity: 1,
              unitPrice: 85000,
              totalPrice: 85000,
            ),
            QuoteItem(
              description: 'Wardrobe - Sliding Shutter - with Laminates',
              dimensions: "8'w x 7'h ft",
              areaOrQuantity: 56,
              unitPrice: 1850,
              totalPrice: 103600,
            ),
            QuoteItem(
              description: 'Walk-In Wardrobe - Loft Units - with Laminate',
              dimensions: "8'w x 2'h ft",
              areaOrQuantity: 16,
              unitPrice: 1150,
              totalPrice: 18400,
            ),
            QuoteItem(
              description: 'Wall Light',
              areaOrQuantity: 1,
              unitPrice: 3000,
              totalPrice: 3000,
            ),
            QuoteItem(
              description: 'Bedback Panel with duco paint and louvers',
              dimensions: "10'w x 9.5'h ft",
              areaOrQuantity: 95,
              unitPrice: 800,
              totalPrice: 76000,
            ),
          ],
        ),
        QuoteSection(
          title: 'Other',
          items: [
            QuoteItem(
              description: 'False Ceiling - Painting - Asian Paints',
              areaOrQuantity: 120,
              unitPrice: 25,
              totalPrice: 3000,
            ),
            QuoteItem(
              description: 'False Ceiling - Saint Gobain Brand',
              areaOrQuantity: 120,
              unitPrice: 60,
              totalPrice: 7200,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Quote Generator'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuotePreviewScreen(
                  quote: _getSampleQuote(),
                ),
              ),
            );
          },
          child: const Text('Generate Sample Quote'),
        ),
      ),
    );
  }
}
