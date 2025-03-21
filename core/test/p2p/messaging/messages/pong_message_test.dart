import 'dart:typed_data';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/messages/pong_message.dart';
import 'package:test/test.dart';
/*
The “pong” message replies to a “ping” message, proving to the pinging node that the ponging node is still alive. 
Node will, by default, disconnect from any clients which have not responded to a “ping” message within 20 minutes.
To allow nodes to keep track of latency, the “pong” message sends back the same nonce received in the “ping” message it is replying to.
The format of the “pong” message is identical to the “ping” message; only the message header differs.

Structure of the message:
  Nonce:                  8 bytes 
*/
void main() {
  group('PongMessage', () {
    test('should have correct command', () {
      final pongMessage = PongMessage(nonce: Uint8List(8));
      expect(pongMessage.command, equals(MessageCommand.pong));
    });

    test('should serialize nonce correctly', () {
      final nonce = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final pongMessage = PongMessage(nonce: nonce);
      
      final serialized = pongMessage.payload();
      
      expect(serialized, equals(nonce));
    });

    test('should deserialize payload correctly', () {
      final nonce = Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]);
      
      final deserialized = PongMessage.deserialize(nonce);
      
      expect(deserialized.nonce, equals(nonce));
    });

    test('should handle empty payload', () {
      final emptyPayload = Uint8List(0);
      final deserialized = PongMessage.deserialize(emptyPayload);
      
      expect(deserialized.nonce, isEmpty);
    });

    test('should create valid instance for ping-pong round trip', () {
      // Simulate receiving a ping with a specific nonce
      final pingNonce = Uint8List.fromList([1, 3, 5, 7, 9, 11, 13, 15]);
      
      // Create pong with that nonce
      final pongMessage = PongMessage(nonce: pingNonce);
      
      // Serialize
      final serialized = pongMessage.payload();
      
      // Deserialize (simulating receiving the message)
      final received = PongMessage.deserialize(serialized);
      
      // Verify nonce is preserved through serialization/deserialization
      expect(received.nonce, equals(pingNonce));
    });
  });
}