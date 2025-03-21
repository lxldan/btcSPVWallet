import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/message.dart';
import 'dart:typed_data';

/*
The verack message is sent in reply to 'version' message. 
This message consists of only a message header with the command string "verack".

Structure of the message:
  No payload
*/
class VerackMessage implements Message {
  
  @override
  MessageCommand get command => MessageCommand.verack;

  @override
  Uint8List payload() {
    return Uint8List(0);
  }
}