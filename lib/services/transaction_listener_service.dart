import 'package:telephony/telephony.dart';
import 'notification_service.dart';

void onBackgroundMessage(SmsMessage message) {
  TransactionListenerService._handleMessage(message);
}

class TransactionListenerService {
  static final TransactionListenerService _instance = TransactionListenerService._internal();
  factory TransactionListenerService() => _instance;
  TransactionListenerService._internal();

  final Telephony _telephony = Telephony.instance;

  Future<void> initialize() async {
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == true) {
      _telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          _handleMessage(message);
        },
        onBackgroundMessage: onBackgroundMessage,
      );
    }
  }

  static void _handleMessage(SmsMessage message) {
    if (message.body == null) return;
    final text = message.body!.toLowerCase();

    // Very basic regex to catch amounts after common keywords
    // Real implementation would be much more sophisticated
    final regex = RegExp(r"(spent|paid|debited)[\s\w]*?(rs\.?|inr|\$)\s?(\d+(?:\.\d{1,2})?)");
    final match = regex.firstMatch(text);

    if (match != null && match.groupCount >= 3) {
      final amount = match.group(3);
      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: "New Transaction Detected",
        body: "Amount: $amount. Tap to add to SpendMind.",
      );
    }
  }
}
