import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'dart:typed_data';

class GetAddrMessage implements Message {
  @override
  MessageCommand get command => MessageCommand.getaddr;

  @override
  Uint8List payload() {
    return Uint8List(0);
  }
} 