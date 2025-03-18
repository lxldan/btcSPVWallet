import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'dart:typed_data';

class VrackMessage implements Message {
  
  @override
  MessageCommand get command => MessageCommand.verack;

  @override
  Uint8List payload() {
    return Uint8List(0);
  }

  Uint8List serialize() {
    final payloadData = payload();
    final messageSize = payloadData.length;
    final message = ByteData(1 + messageSize);
    message.setUint8(0, command.index);
    for (int i = 0; i < messageSize; i++) {
      message.setUint8(1 + i, payloadData[i]);
    }
    return message.buffer.asUint8List();
  }
}