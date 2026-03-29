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
import 'services/sms_sync_service.dart';
import 'services/payment_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request();
  await NotificationService().initialize();
  // Call syncRecentSms periodically or on app launch to analyze new bank texts
  // without risking Google Play SMS background policy rejections.
  await SmsSyncService().syncRecentSms();
  runApp(const SpendMindApp());
}

class SpendMindApp extends StatefulWidget {
  const SpendMindApp({Key? key}) : super(key: key);

  @override
  _SpendMindAppState createState() => _SpendMindAppState();
}

class _SpendMindAppState extends State<SpendMindApp> {
  late ExpenseProvider _expenseProvider;

  @override
  void initState() {
    super.initState();
    _expenseProvider = ExpenseProvider();

    // Initialize background payment notification listener
    PaymentNotificationService().initialize(() {
      // Reload provider data if a transaction was auto-logged
      _expenseProvider.loadData();
      // Optional: Since the isolate sent this, we can assume it successfully saved.
      // A local notification could be triggered here if desired, safely on the main thread.
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _expenseProvider),
      ],
      child: MaterialApp(
        title: 'Money Saver',
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
                  icon: Icon(Icons.bar_chart),
                  label: 'Stats',
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
