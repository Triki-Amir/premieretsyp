import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/energy_data_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen_blockchain.dart';
import 'screens/my_factory_screen.dart';
import 'screens/smart_contracts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/blockchain_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => EnergyDataProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Next Gen Power',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
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
  bool _isAuthenticated = false;
  String _activeScreen = 'dashboard';
  int _selectedIndex = 0;

  void _handleLogin() {
    setState(() {
      _isAuthenticated = true;
      _activeScreen = 'dashboard';
      _selectedIndex = 0;
    });
  }

  void _handleSignOut() {
    setState(() {
      _isAuthenticated = false;
      _activeScreen = 'dashboard';
    });
  }

  void _handleNavigate(String screen) {
    setState(() {
      _activeScreen = screen;
      // Update bottom nav index when navigating
      if (screen == 'dashboard') {
        _selectedIndex = 0;
      } else if (screen == 'myFactory') {
        _selectedIndex = 1;
      } else if (screen == 'offers') {
        _selectedIndex = 2;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _activeScreen = 'dashboard';
          break;
        case 1:
          _activeScreen = 'myFactory';
          break;
        case 2:
          _activeScreen = 'offers';
          break;
      }
    });
  }

  Widget _getScreen() {
    switch (_activeScreen) {
      case 'dashboard':
        return DashboardScreenNew(onNavigate: _handleNavigate);
      case 'myFactory':
        return MyFactoryScreen(onNavigate: _handleNavigate);
      case 'offers':
        return SmartContractsScreen(onNavigate: _handleNavigate);
      case 'blockchain':
        return BlockchainScreen(onBack: () => _handleNavigate('dashboard'));
      case 'profile':
        return ProfileScreen(
          onSignOut: _handleSignOut,
          onBack: () => _handleNavigate('dashboard'),
        );
      default:
        return DashboardScreenNew(onNavigate: _handleNavigate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return LoginScreen(onLogin: _handleLogin);
    }

    final showBottomNav = _activeScreen != 'blockchain' && 
                          _activeScreen != 'profile';

    return Scaffold(
      body: _getScreen(),
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.factory),
                  label: 'My Factory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description),
                  label: 'Offers',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.grey.shade900,
              onTap: _onItemTapped,
            )
          : null,
    );
  }
}
