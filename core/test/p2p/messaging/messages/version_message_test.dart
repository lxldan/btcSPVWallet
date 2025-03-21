import 'package:core/p2p/messaging/messages/version_message.dart';
import 'package:test/test.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:core/p2p/messaging/message_command.dart';
/*
Structure of the version message:
  Version:                4 bytes - 31900 (version 0.3.19)
  Services:               8 bytes - 1 (NODE_NETWORK services)
  Timestamp:              8 bytes - Mon Dec 20 21:50:14 EST 2010
  Recipient Address:     26 bytes - Network Address information
  Sender Address:        26 bytes - Network Address information
  Node Unique ID:         8 bytes - Random unique ID for the node
  Sub-version String:     1 byte  - Empty string (0 bytes long)
  Last Block Index:       4 bytes - Block #98645
*/
void main() {
  group('VersionMessage', () {
    final int protocolVersion = 70015;
    final int services = 1;
    final int timestamp = 1616325658;
    final String userAgent = '/Satoshi:0.21.0/';
    final int lastBlock = 679000;
    final int nonce = 12345678;
    final bool relay = true;

    test('should create version message with correct values', () {
      final message = VersionMessage(
        protocolVersion: protocolVersion,
        services: services,
        timestamp: timestamp,
        userAgent: userAgent,
        lastBlock: lastBlock,
        nonce: nonce,
        relay: relay,
      );

      expect(message.protocolVersion, equals(protocolVersion));
      expect(message.services, equals(services));
      expect(message.timestamp, equals(timestamp));
      expect(message.userAgent, equals(userAgent));
      expect(message.lastBlock, equals(lastBlock));
      expect(message.nonce, equals(nonce));
      expect(message.relay, equals(relay));
      expect(message.command, equals(MessageCommand.version));
    });

    test('should serialize to correct binary format', () {
      final message = VersionMessage(
        protocolVersion: protocolVersion,
        services: services,
        timestamp: timestamp,
        userAgent: userAgent,
        lastBlock: lastBlock,
        nonce: nonce,
        relay: relay,
      );

      final payload = message.payload();
      expect(payload, isA<Uint8List>());

      final data = ByteData.sublistView(payload);

      // Verify serialized fields match expected values
      int offset = 0;

      // Version - 4 bytes
      expect(data.getInt32(offset, Endian.little), equals(protocolVersion));
      offset += 4;

      // Services - 8 bytes
      expect(data.getUint64(offset, Endian.little), equals(services));
      offset += 8;

      // Timestamp - 8 bytes
      expect(data.getInt64(offset, Endian.little), equals(timestamp));
      offset += 8;

      // Skip addr_recv - 26 bytes
      offset += 26;

      // Skip addr_from - 26 bytes
      offset += 26;

      // Nonce - 8 bytes
      expect(data.getUint64(offset, Endian.little), equals(nonce));
      offset += 8;

      // User agent length - 1 byte
      final userAgentBytes = utf8.encode(userAgent);
      expect(data.getUint8(offset), equals(userAgentBytes.length));
      offset += 1;

      // User agent - variable length
      final extractedUserAgentBytes = payload.sublist(
        offset,
        offset + userAgentBytes.length,
      );
      expect(utf8.decode(extractedUserAgentBytes), equals(userAgent));
      offset += userAgentBytes.length;

      // Last block - 4 bytes
      expect(data.getInt32(offset, Endian.little), equals(lastBlock));
      offset += 4;

      // Relay - 1 byte
      expect(data.getUint8(offset), equals(1));
    });

    test('should deserialize correctly from binary data', () {
      // First create a message and serialize it to binary
      final originalMessage = VersionMessage(
        protocolVersion: protocolVersion,
        services: services,
        timestamp: timestamp,
        userAgent: userAgent,
        lastBlock: lastBlock,
        nonce: nonce,
        relay: relay,
      );

      final serialized = originalMessage.payload();

      // Now deserialize it back to a VersionMessage
      final deserializedMessage = VersionMessage.deserialize(serialized);

      // Check if all fields match the original
      expect(deserializedMessage.protocolVersion, equals(protocolVersion));
      expect(deserializedMessage.services, equals(services));
      expect(deserializedMessage.timestamp, equals(timestamp));
      expect(deserializedMessage.userAgent, equals(userAgent));
      expect(deserializedMessage.lastBlock, equals(lastBlock));
      expect(deserializedMessage.nonce, equals(nonce));
      expect(deserializedMessage.relay, equals(relay));
    });

    test(
      'factory create should generate valid message with current timestamp',
      () {
        final message = VersionMessage.create(
          protocolVersion: protocolVersion,
          services: services,
          userAgent: userAgent,
          lastBlock: lastBlock,
          relay: relay,
        );

        // Timestamp should be recent (within 10 seconds of current time)
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        expect((message.timestamp - now).abs() < 10, isTrue);

        // Nonce should be non-zero
        expect(message.nonce, isNot(equals(0)));

        // Other fields should match input
        expect(message.protocolVersion, equals(protocolVersion));
        expect(message.services, equals(services));
        expect(message.userAgent, equals(userAgent));
        expect(message.lastBlock, equals(lastBlock));
        expect(message.relay, equals(relay));
      },
    );

    test('should correctly handle relay flag', () {
      // Test with relay = false
      final message = VersionMessage(
        protocolVersion: protocolVersion,
        services: services,
        timestamp: timestamp,
        userAgent: userAgent,
        lastBlock: lastBlock,
        nonce: nonce,
        relay: false,
      );

      final serialized = message.payload();
      final deserializedMessage = VersionMessage.deserialize(serialized);

      expect(deserializedMessage.relay, isFalse);
    });

    test('should handle empty user agent correctly', () {
      final message = VersionMessage(
        protocolVersion: protocolVersion,
        services: services,
        timestamp: timestamp,
        userAgent: '', // Empty user agent
        lastBlock: lastBlock,
        nonce: nonce,
        relay: relay,
      );

      final serialized = message.payload();
      final deserializedMessage = VersionMessage.deserialize(serialized);

      expect(deserializedMessage.userAgent, equals(''));
    });

    test('should handle very long user agent correctly', () {
      final longUserAgent = 'A' * 100; // 100 letter 'A's

      final message = VersionMessage(
        protocolVersion: protocolVersion,
        services: services,
        timestamp: timestamp,
        userAgent: longUserAgent,
        lastBlock: lastBlock,
        nonce: nonce,
        relay: relay,
      );

      final serialized = message.payload();
      final deserializedMessage = VersionMessage.deserialize(serialized);

      expect(deserializedMessage.userAgent, equals(longUserAgent));
    });

    test('should handle non-ASCII characters in user agent', () {
      final unicodeUserAgent = '/Satoshi:0.21.0/😀'; // With emoji

      final message = VersionMessage(
        protocolVersion: protocolVersion,
        services: services,
        timestamp: timestamp,
        userAgent: unicodeUserAgent,
        lastBlock: lastBlock,
        nonce: nonce,
        relay: relay,
      );

      final serialized = message.payload();
      final deserializedMessage = VersionMessage.deserialize(serialized);

      expect(deserializedMessage.userAgent, equals(unicodeUserAgent));
    });

    test('toString should return a human-readable representation', () {
      final message = VersionMessage(
        protocolVersion: protocolVersion,
        services: services,
        timestamp: timestamp,
        userAgent: userAgent,
        lastBlock: lastBlock,
        nonce: nonce,
        relay: relay,
      );

      final stringRepresentation = message.toString();

      expect(stringRepresentation, contains('VersionMessage'));
      expect(stringRepresentation, contains(protocolVersion.toString()));
      expect(stringRepresentation, contains(services.toString()));
      expect(stringRepresentation, contains(timestamp.toString()));
      expect(stringRepresentation, contains(userAgent));
      expect(stringRepresentation, contains(lastBlock.toString()));
      expect(stringRepresentation, contains(nonce.toString()));
      expect(stringRepresentation, contains(relay.toString()));
    });
  });
}
