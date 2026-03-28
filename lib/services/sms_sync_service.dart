import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

class SmsSyncService {
  static final SmsSyncService _instance = SmsSyncService._internal();
  factory SmsSyncService() => _instance;
  SmsSyncService._internal();

  final SmsQuery _query = SmsQuery();

  Future<void> syncRecentSms() async {
    var permission = await Permission.sms.status;
    if (permission.isGranted) {
      await _processSms();
    } else {
      final status = await Permission.sms.request();
      if (status.isGranted) {
        await _processSms();
      }
    }
  }

  Future<void> _processSms() async {
    // Read SMS messages received in the last hour as a periodic sync alternative
    // Note: Background SMS listeners require native Android BroadcastReceivers
    // which are highly restricted by Google Play. Polling recent SMS on app launch
    // or via a button is a safer, policy-compliant approach for this feature.

    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 20,
    );

    final now = DateTime.now();

    for (var message in messages) {
      if (message.date == null || message.body == null) continue;

      final msgDate = message.date!;
      // Only process messages from the last 2 hours
      if (now.difference(msgDate).inHours < 2) {
         _detectTransaction(message.body!);
      }
    }
  }

  void _detectTransaction(String text) {
    final textLower = text.toLowerCase();

    // Very basic regex to catch amounts after common keywords
    final regex = RegExp(r"(spent|paid|debited|rs\.?|inr|\$)\s*(\d+(?:\.\d{1,2})?)");
    final match = regex.firstMatch(textLower);

    if (textLower.contains('spent') || textLower.contains('debited') || textLower.contains('paid')) {
      if (match != null && match.groupCount >= 2) {
        final amount = match.group(2);
        NotificationService().showNotification(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: "New Transaction Detected",
          body: "Amount: $amount. Tap to add to SpendMind.",
        );
      }
    }
  }
}
