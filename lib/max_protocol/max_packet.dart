
import 'dart:convert';

/// MAX protocol packet — mirrors the wire format used by MAX/OneMe
/// (ver, cmd, opcode, seq, payload), as reverse-engineered in
/// python-max-client (huxuxuya/python-max-client).
class MaxPacket {
  final int ver;
  final int cmd;
  final int opcode;
  final int seq;
  final Map<String, dynamic> payload;

  const MaxPacket({
    required this.ver,
    required this.cmd,
    required this.opcode,
    required this.seq,
    required this.payload,
  });

  factory MaxPacket.fromJson(Map<String, dynamic> json) => MaxPacket(
        ver: json['ver'] as int,
        cmd: json['cmd'] as int,
        opcode: json['opcode'] as int,
        seq: json['seq'] as int,
        payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      );

  Map<String, dynamic> toJson() => {
        'ver': ver,
        'cmd': cmd,
        'opcode': opcode,
        'seq': seq,
        'payload': payload,
      };

  String encode() => jsonEncode(toJson());

  static MaxPacket decode(String raw) => MaxPacket.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Known opcodes observed in the MAX protocol.
class MaxOpcode {
  static const int auth = 6;
  static const int sendSmsCode = 17;
  static const int signIn = 19;
  static const int loginByToken = 19;
  static const int newMessage = 128;
  static const int editMessage = 67;
  static const int sendMessage = 64;
  static const int getChats = 49;
  static const int getHistory = 49;
}
