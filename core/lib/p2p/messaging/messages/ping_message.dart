import 'dart:typed_data';
import 'dart:math';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
/*
The “ping” message helps confirm that the receiving peer is still connected. 
If a TCP/IP error is encountered when sending the “ping” message (such as a connection timeout), the transmitting node can assume that the receiving node is disconnected. 
The response to a “ping” message is the “pong” message.

Structure of the message:
  Nonce:                  8 bytes 
*/
class PingMessage implements Message {
  Uint8List nonce;

  PingMessage() : nonce = _generateRandomNonce();
  
  PingMessage._withNonce(this.nonce);

  @override
  MessageCommand get command => MessageCommand.ping;

  @override
  Uint8List payload() {
    return nonce;
  }
  static Uint8List _generateRandomNonce() {
    final random = Random.secure();
    final nonce = Uint8List(8);
    for (var i = 0; i < 8; i++) {
      nonce[i] = random.nextInt(256);
    }
    return nonce;
  }

  factory PingMessage.deserialize(Uint8List payload) {
    return PingMessage._withNonce(payload);
  }
}