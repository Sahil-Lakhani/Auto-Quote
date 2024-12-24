import 'package:auto_quote/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'models/quote_model.dart';
import 'screens/quote_preview_screen.dart';
import 'screens/quote_form_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/template_selection_screen.dart';
import 'package:auto_quote/providers/quote_form_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuoteFormProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
    const TemplateSelectionScreen(),
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
              quantity: 1,
              unitPrice: 85000,
              totalPrice: 85000,
            ),
            QuoteItem(
              description: 'Wardrobe - Sliding Shutter - with Laminates',
              dimensions: "8'w x 7'h ft",
              quantity: 56,
              unitPrice: 1850,
              totalPrice: 103600,
            ),
            QuoteItem(
              description: 'Walk-In Wardrobe - Loft Units - with Laminate',
              dimensions: "8'w x 2'h ft",
              quantity: 16,
              unitPrice: 1150,
              totalPrice: 18400,
            ),
            QuoteItem(
              description: 'Wall Light',
              quantity: 1,
              unitPrice: 3000,
              totalPrice: 3000,
            ),
            QuoteItem(
              description: 'Bedback Panel with duco paint and louvers',
              dimensions: "10'w x 9.5'h ft",
              quantity: 95,
              unitPrice: 800,
              totalPrice: 76000,
            ),
          ],
          roomTotal: 1000,
        ),
        QuoteRoomType(
          title: 'Other',
          items: [
            QuoteItem(
              description: 'False Ceiling - Painting - Asian Paints',
              quantity: 120,
              unitPrice: 25,
              totalPrice: 3000,
            ),
            QuoteItem(
              description: 'False Ceiling - Saint Gobain Brand',
              quantity: 120,
              unitPrice: 60,
              totalPrice: 7200,
            ),
          ],
          roomTotal: 1000,
        ),
      ],
      transportCharges: 100,
      laborCharges: 100,
      subtotal: 1000,
      cgst: 800,
      sgst: 800,
      grandTotal: 1800,
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
            icon: Icon(Icons.dashboard_customize),
            label: 'Templates',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
