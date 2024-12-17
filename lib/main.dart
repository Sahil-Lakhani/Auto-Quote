import 'package:auto_quote/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'models/quote_model.dart';
import 'screens/quote_preview_screen.dart';
import 'screens/quote_form_screen.dart';
import 'screens/product_form_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Quote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const QuoteFormScreen(),
    const ProductFormScreen(),
    QuotePreviewScreen(quote: _getSampleQuote()),
  ];

  static Quote _getSampleQuote() {
    return Quote(
      companyName: 'Design Que',
      address: 'address xyz',
      phone: '99669 22000',
      clientName: 'ravi varma',
      date: DateTime(2024, 10, 30),
      sections: [
        QuoteRoomType(
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
        QuoteRoomType(
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Quote',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'Preview',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
