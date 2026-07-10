
enum MaxgramMessageStatus { sending, sent, read }

class MaxgramMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isOutgoing;
  final MaxgramMessageStatus status;

  const MaxgramMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isOutgoing,
    this.status = MaxgramMessageStatus.sent,
  });
}
