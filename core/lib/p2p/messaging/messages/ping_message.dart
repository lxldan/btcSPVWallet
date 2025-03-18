import 'dart:typed_data';
import 'dart:math';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';

class PingMessage implements Message {
  final Uint8List nonce;

  PingMessage({Uint8List? nonce}) : 
    nonce = nonce ?? _generateRandomNonce();

  static Uint8List _generateRandomNonce() {
    final random = Random.secure();
    final nonce = Uint8List(8);
    for (var i = 0; i < 8; i++) {
      nonce[i] = random.nextInt(256);
    }
    return nonce;
  }

  @override
  MessageCommand get command => MessageCommand.ping;

  @override
  Uint8List payload() {
    return nonce;
  }

  factory PingMessage.deserialize(Uint8List payload) {
    if (payload.isEmpty) {
      return PingMessage(nonce: Uint8List(0));
    }
    return PingMessage(nonce: payload);
  }
}
