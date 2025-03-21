import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'dart:typed_data';
/*
The “getaddr” message requests an “addr” or “addrv2” message from the receiving node, preferably one with lots of addresses of other receiving nodes.
The transmitting node can use those addresses to quickly update its database of available nodes rather than waiting for unsolicited “addr” or “addrv2” messages to arrive over time.

Structure of the message:
  No payload
*/
class GetAddrMessage implements Message {
  
  @override
  MessageCommand get command => MessageCommand.getaddr;

  @override
  Uint8List payload() {
    return Uint8List(0);
  }
} 