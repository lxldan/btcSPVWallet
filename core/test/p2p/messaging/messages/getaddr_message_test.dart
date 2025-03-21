import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/messages/getaddr_message.dart';
import 'dart:typed_data';
import 'package:test/test.dart';
/*
The “getaddr” message requests an “addr” or “addrv2” message from the receiving node, preferably one with lots of addresses of other receiving nodes.
The transmitting node can use those addresses to quickly update its database of available nodes rather than waiting for unsolicited “addr” or “addrv2” messages to arrive over time.

Structure of the message:
  No payload
*/
void main() {
  group('GetAddrMessage', () {
    test('should have correct command', () {
      final message = GetAddrMessage();
      expect(message.command, equals(MessageCommand.getaddr));
    });

    test('should have empty payload', () {
      final message = GetAddrMessage();
      final payload = message.payload();
      
      expect(payload, isA<Uint8List>());
      expect(payload.length, equals(0));
    });

    test('should create valid empty message', () {
      final message = GetAddrMessage();
      
      expect(message, isA<GetAddrMessage>());
      expect(message.command, MessageCommand.getaddr);
      expect(message.payload().isEmpty, isTrue);
    });
  });
}