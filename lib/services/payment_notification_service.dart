import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:intl/intl.dart';
import '../data/db_helper.dart';
import '../data/models/expense.dart';

import 'dart:ui' as ui;

// Mandatory background port setup
const String _portName = 'notification_listener_port';

// Must be a top-level or static function
@pragma('vm:entry-point')
void _notificationCallback(NotificationEvent evt) async {
  try {
    // For background isolates, DartPluginRegistrant is typically required instead of WidgetsFlutterBinding.
    ui.DartPluginRegistrant.ensureInitialized();
    if (evt.packageName == null || evt.title == null || evt.text == null) return;

  final title = evt.title!.toLowerCase();
  final body = evt.text!.toLowerCase();
  final pkg = evt.packageName!.toLowerCase();

  // Basic filter to ignore non-payment apps or random notifications
  if (!title.contains('paid') && !title.contains('sent') && !title.contains('debited') &&
      !body.contains('paid') && !body.contains('sent') && !body.contains('debited') &&
      !pkg.contains('pay') && !pkg.contains('bank')) {
    return;
  }

  // Regex to extract currency amounts like $50.00, Rs 500, ₹50, etc.
  final amountRegex = RegExp(r"(rs\.?|inr|\$|₹|€|£|¥)\s?(\d+(?:\.\d{1,2})?)");
  final match = amountRegex.firstMatch(body) ?? amountRegex.firstMatch(title);

  if (match != null && match.groupCount >= 2) {
    final amountStr = match.group(2);
    if (amountStr != null) {
      final amount = double.tryParse(amountStr);
      if (amount != null && amount > 0) {

        final dbHelper = DatabaseHelper();
        final expense = Expense(
          amount: amount,
          category: 'Others', // Default
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          note: 'Auto-added from ${evt.packageName}',
        );

        await dbHelper.insertExpense(expense);

        // Notify the UI isolate if it is active.
        final SendPort? send = IsolateNameServer.lookupPortByName(_portName);
        if (send != null) {
          send.send('NEW_TRANSACTION');
        }
      }
    }
  }
  } catch (e) {
    print('Background notification parsing failed: $e');
  }
}

class PaymentNotificationService {
  static final PaymentNotificationService _instance = PaymentNotificationService._internal();
  factory PaymentNotificationService() => _instance;
  PaymentNotificationService._internal();

  final ReceivePort _port = ReceivePort();

  Future<void> initialize(Function() onNewTransaction) async {
    // Register port to communicate from background isolate to main UI isolate
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_port.sendPort, _portName);

    _port.listen((message) {
      if (message == 'NEW_TRANSACTION') {
        onNewTransaction();
      }
    });

    try {
      final hasPermission = await NotificationsListener.hasPermission;
      if (hasPermission == true) {
        // Initialize the listener service. If already running, this is safe.
        await NotificationsListener.initialize(callbackHandle: _notificationCallback);
      }
    } catch (e) {
      print('Error initializing notification listener: $e');
    }
  }
}
