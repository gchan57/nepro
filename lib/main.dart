import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'analytics_page.dart';
import 'mlmod.dart'; // Camera / local model page
import 'online_model_page.dart'; // Online model page

Future<void> main() async {
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
      debugShowCheckedModeBanner: false,
      title: 'AgroSmart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(238, 186, 248, 204),
        ),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // Keep this list in sync with bottom navigation items
  static final List<Widget> _pages = <Widget>[
    const AnalyticsPage(),
    const CameraHomeScreen(),
    const OnlineModelPage(),
  ];

  void _onItemTapped(int index) {
    if (index < 0 || index >= _pages.length) return; // defensive
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sanity assert (only runs in debug mode)
    assert(_pages.length == 3, 'Ensure _pages length matches BottomNavigationBar items count');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: SizedBox.expand(
          // give a stable key so AnimatedSwitcher recognizes changes
          key: ValueKey<int>(_selectedIndex),
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            selectedItemColor: const Color.fromARGB(255, 139, 240, 144),
            unselectedItemColor: const Color.fromARGB(255, 120, 90, 90),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_outlined),
                activeIcon: Icon(Icons.camera_alt),
                label: 'Model',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.cloud_outlined),
                activeIcon: Icon(Icons.cloud),
                label: 'Online',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
