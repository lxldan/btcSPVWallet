import 'dart:typed_data';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';

/*
The “pong” message replies to a “ping” message, proving to the pinging node that the ponging node is still alive. 
Node will, by default, disconnect from any clients which have not responded to a “ping” message within 20 minutes.
To allow nodes to keep track of latency, the “pong” message sends back the same nonce received in the “ping” message it is replying to.
The format of the “pong” message is identical to the “ping” message; only the message header differs.

Structure of the message:
  Nonce:                  8 bytes 
*/
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
