
class MaxgramChat {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;
  final int avatarColorIndex;
  final String? avatarLetter;

  const MaxgramChat({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
    this.avatarColorIndex = 0,
    this.avatarLetter,
  });
}
