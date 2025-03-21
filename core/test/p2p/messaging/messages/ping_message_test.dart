import 'package:test/test.dart';
import 'package:core/p2p/messaging/messages/ping_message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'dart:typed_data';
/*
The “ping” message helps confirm that the receiving peer is still connected. 
If a TCP/IP error is encountered when sending the “ping” message (such as a connection timeout), the transmitting node can assume that the receiving node is disconnected. 
The response to a “ping” message is the “pong” message.

Structure of the message:
  Nonce:                  8 bytes 
*/
void main() {
  group('PingMessage', () {
    test('initializes with a random nonce of 8 bytes', () {
      final pingMessage = PingMessage();
      expect(pingMessage.nonce.length, equals(8));
      expect(pingMessage.nonce, isA<Uint8List>());
    });

    test('generates different nonce for different instances', () {
      final pingMessage1 = PingMessage();
      final pingMessage2 = PingMessage();
      expect(pingMessage1.nonce, isNot(equals(pingMessage2.nonce)));
    });

    test('payload returns the nonce', () {
      final pingMessage = PingMessage();
      final payload = pingMessage.payload();
      expect(payload, equals(pingMessage.nonce));
    });

    test('command returns ping', () {
      final pingMessage = PingMessage();
      expect(pingMessage.command, equals(MessageCommand.ping));
    });

    test('deserialize creates a PingMessage with the given payload', () {
      final originalNonce = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final pingMessage = PingMessage.deserialize(originalNonce);
      expect(pingMessage.nonce, equals(originalNonce));
      expect(pingMessage.payload(), equals(originalNonce));
    });

    test('deserialize handles arbitrary payload data', () {
      final testData = Uint8List.fromList([255, 0, 128, 64, 32, 16, 8, 4]);
      final pingMessage = PingMessage.deserialize(testData);
      expect(pingMessage.nonce, equals(testData));
    });
  });
}
