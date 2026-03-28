import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/expense_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/add_expense_screen.dart';
import 'dart:ui';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  // Request permissions and initialize SMS listener in background
  // await TransactionListenerService().initialize();
  runApp(const SpendMindApp());
}

class SpendMindApp extends StatelessWidget {
  const SpendMindApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: MaterialApp(
        title: 'SpendMind AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/add_expense': (context) => const AddExpenseScreen(),
          '/insights': (context) => const InsightsScreen(),
          '/chat': (context) => const ChatScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const InsightsScreen(),
    const ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        decoration: AppTheme.glassDecoration(
          opacity: 0.2,
          color: Colors.black,
          borderRadius: 30,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              currentIndex: _currentIndex >= 1 ? _currentIndex + 1 : _currentIndex,
              onTap: (index) {
                if (index == 1) {
                  Navigator.pushNamed(context, '/add_expense');
                  return;
                }
                setState(() {
                  _currentIndex = index >= 1 ? index - 1 : index;
                });
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  label: 'Add',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.insights),
                  label: 'Insights',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble),
                  label: 'AI Chat',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
