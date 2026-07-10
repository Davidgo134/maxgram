
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'max_packet.dart';

/// WebSocket client for the MAX/OneMe messenger protocol.
/// Architecture mirrors python-max-client (huxuxuya/python-max-client):
/// connect -> send_code(phone) -> sign_in(token, smsCode) -> set_callback.
///
/// Endpoint and exact auth flow are reverse-engineered by the community;
/// this class isolates all protocol logic behind a clean Dart API so the
/// Maxgram UI layer never touches raw WebSocket packets directly.
class MaxClient {
  static const String _endpoint = 'wss://ws-api.max.ru/websocket';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  int _seq = 0;
  String? _loginToken;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  final Map<int, Completer<MaxPacket>> _pendingRequests = {};

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    _channel = WebSocketChannel.connect(Uri.parse(_endpoint));
    _subscription = _channel!.stream.listen(
      _handleRawMessage,
      onError: (e) => _messageController.addError(e),
      onDone: () => _channel = null,
    );
  }

  void _handleRawMessage(dynamic raw) {
    try {
      final packet = MaxPacket.decode(raw as String);

      final pending = _pendingRequests.remove(packet.seq);
      if (pending != null) {
        pending.complete(packet);
        return;
      }

      if (packet.opcode == MaxOpcode.newMessage) {
        _messageController.add(packet.payload);
      }
    } catch (_) {
      // malformed/unrecognized packet — ignore defensively
    }
  }

  Future<MaxPacket> _sendAndWait(int opcode, Map<String, dynamic> payload) {
    final seq = ++_seq;
    final packet = MaxPacket(ver: 1, cmd: 0, opcode: opcode, seq: seq, payload: payload);
    final completer = Completer<MaxPacket>();
    _pendingRequests[seq] = completer;
    _channel?.sink.add(packet.encode());

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pendingRequests.remove(seq);
        throw TimeoutException('MAX protocol request timed out (opcode=$opcode)');
      },
    );
  }

  /// Step 1 of phone auth: request an SMS code, returns a login token
  /// that must be passed back into [signIn] along with the SMS code.
  Future<String> sendSmsCode(String phoneNumber) async {
    final response = await _sendAndWait(MaxOpcode.sendSmsCode, {'phone': phoneNumber});
    final token = response.payload['token'] as String?;
    if (token == null) {
      throw MaxAuthException('No login token returned for sendSmsCode');
    }
    return token;
  }

  /// Step 2 of phone auth: confirm SMS code, persist login token
  /// for future silent [loginByToken] calls.
  Future<void> signIn(String smsToken, int smsCode) async {
    final response = await _sendAndWait(MaxOpcode.signIn, {
      'token': smsToken,
      'code': smsCode,
    });
    final attrs = response.payload['tokenAttrs'] as Map<String, dynamic>?;
    final loginToken = attrs?['LOGIN']?['token'] as String?;
    if (loginToken == null) {
      throw MaxAuthException('Sign-in did not return a persistent login token');
    }
    _loginToken = loginToken;
  }

  /// Silent re-authentication using a previously stored login token.
  Future<void> loginByToken(String token) async {
    await _sendAndWait(MaxOpcode.loginByToken, {'token': token});
    _loginToken = token;
  }

  String? get persistedLoginToken => _loginToken;

  Future<void> sendMessage({required String chatId, required String text}) async {
    await _sendAndWait(MaxOpcode.sendMessage, {
      'chatId': chatId,
      'message': {'text': text},
    });
  }

  Future<void> editMessage({required String chatId, required String messageId, required String text}) async {
    await _sendAndWait(MaxOpcode.editMessage, {
      'chatId': chatId,
      'messageId': messageId,
      'text': text,
    });
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    final response = await _sendAndWait(MaxOpcode.getChats, {});
    final chats = response.payload['chats'] as List<dynamic>?;
    return chats?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _messageController.close();
    disconnect();
  }
}

class MaxAuthException implements Exception {
  final String message;
  MaxAuthException(this.message);
  @override
  String toString() => 'MaxAuthException: $message';
}
