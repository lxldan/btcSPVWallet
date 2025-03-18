import 'dart:typed_data';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';

class PongMessage implements Message {
  final Uint8List nonce;

  PongMessage({required this.nonce});

  @override
  MessageCommand get command => MessageCommand.pong;

  @override
  Uint8List payload() {
    return nonce;
  }

  factory PongMessage.deserialize(Uint8List payload) {
    if (payload.isEmpty) {
      return PongMessage(nonce: Uint8List(0));
    }
    return PongMessage(nonce: payload);
  }
}
