
import 'dart:async';
import '../models_chat.dart';
import '../models_message.dart';
import 'max_client.dart';

/// Repository layer translating raw MAX protocol payloads into
/// Maxgram UI models (MaxgramChat / MaxgramMessage). Keeps screens
/// decoupled from wire-format details (opcode, seq, payload shape).
class MaxRepository {
  final MaxClient client;
  final _chatsController = StreamController<List<MaxgramChat>>.broadcast();
  final Map<String, StreamController<MaxgramMessage>> _chatMessageStreams = {};

  List<MaxgramChat> _cachedChats = [];

  MaxRepository(this.client) {
    client.onMessage.listen(_handleIncomingPayload);
  }

  Stream<List<MaxgramChat>> get chatsStream => _chatsController.stream;

  Stream<MaxgramMessage> messagesStreamFor(String chatId) {
    return _chatMessageStreams.putIfAbsent(chatId, () => StreamController<MaxgramMessage>.broadcast()).stream;
  }

  /// Fetches the chat list from MAX and emits parsed MaxgramChat models.
  Future<List<MaxgramChat>> loadChats() async {
    final rawChats = await client.getChats();
    _cachedChats = rawChats.map(_parseChat).toList();
    _chatsController.add(_cachedChats);
    return _cachedChats;
  }

  MaxgramChat _parseChat(Map<String, dynamic> raw) {
    final title = (raw['title'] ?? raw['name'] ?? 'Unknown') as String;
    final lastMessageRaw = raw['lastMessage'] as Map<String, dynamic>?;
    final timestampMs = (lastMessageRaw?['time'] ?? raw['updateTime'] ?? 0) as int;

    return MaxgramChat(
      id: (raw['id'] ?? raw['chatId']).toString(),
      title: title,
      lastMessage: (lastMessageRaw?['text'] ?? '') as String,
      timestamp: timestampMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
          : DateTime.now(),
      unreadCount: (raw['unreadCount'] ?? 0) as int,
      isMuted: (raw['muted'] ?? false) as bool,
      isPinned: (raw['pinned'] ?? false) as bool,
      avatarColorIndex: title.isNotEmpty ? title.codeUnitAt(0) % 5 : 0,
      avatarLetter: title.isNotEmpty ? title[0] : '?',
    );
  }

  MaxgramMessage _parseMessage(Map<String, dynamic> raw, {required String myUserId}) {
    final senderId = (raw['senderId'] ?? raw['from'] ?? '').toString();
    final timestampMs = (raw['time'] ?? raw['timestamp'] ?? 0) as int;
    final statusRaw = (raw['status'] ?? 'sent') as String;

    return MaxgramMessage(
      id: (raw['id'] ?? raw['messageId'] ?? DateTime.now().microsecondsSinceEpoch).toString(),
      text: (raw['text'] ?? '') as String,
      timestamp: timestampMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
          : DateTime.now(),
      isOutgoing: senderId == myUserId,
      status: _mapStatus(statusRaw),
    );
  }

  MaxgramMessageStatus _mapStatus(String raw) {
    switch (raw) {
      case 'read':
        return MaxgramMessageStatus.read;
      case 'sending':
      case 'pending':
        return MaxgramMessageStatus.sending;
      default:
        return MaxgramMessageStatus.sent;
    }
  }

  void _handleIncomingPayload(Map<String, dynamic> payload) {
    final chatId = (payload['chatId'] ?? '').toString();
    if (chatId.isEmpty) return;

    final message = _parseMessage(payload, myUserId: client.persistedLoginToken ?? '');
    final controller = _chatMessageStreams.putIfAbsent(chatId, () => StreamController<MaxgramMessage>.broadcast());
    controller.add(message);

    final idx = _cachedChats.indexWhere((c) => c.id == chatId);
    if (idx != -1) {
      final updated = MaxgramChat(
        id: _cachedChats[idx].id,
        title: _cachedChats[idx].title,
        lastMessage: message.text,
        timestamp: message.timestamp,
        unreadCount: message.isOutgoing ? _cachedChats[idx].unreadCount : _cachedChats[idx].unreadCount + 1,
        isMuted: _cachedChats[idx].isMuted,
        isPinned: _cachedChats[idx].isPinned,
        avatarColorIndex: _cachedChats[idx].avatarColorIndex,
        avatarLetter: _cachedChats[idx].avatarLetter,
      );
      _cachedChats[idx] = updated;
      _chatsController.add(List.of(_cachedChats));
    }
  }

  Future<void> sendMessage(String chatId, String text) => client.sendMessage(chatId: chatId, text: text);

  void dispose() {
    _chatsController.close();
    for (final c in _chatMessageStreams.values) {
      c.close();
    }
  }
}
