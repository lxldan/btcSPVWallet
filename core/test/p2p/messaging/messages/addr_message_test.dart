import 'package:core/p2p/messaging/messages/addr_message.dart';
import 'package:core/p2p/messaging/messages/adress.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:test/test.dart';
import 'dart:typed_data';

/*
The addr (IP address) message relays connection information for peers on the network.

Structure of the message:
  Count:                  variable integer
  Addresses:              list of Address objects (30 bytes each)
*/
void main() {
  group('AddrMessage', () {
    test('should have correct command', () {
      final message = AddrMessage([]);
      expect(message.command, equals(MessageCommand.addr));
    });

    test('should handle empty address list', () {
      final message = AddrMessage([]);
      final payload = message.payload();
      
      expect(payload, isA<Uint8List>());
      expect(payload.length, equals(1)); // Just the count (0) as a single byte
      expect(payload[0], equals(0));
      
      final deserialized = AddrMessage.deserialize(payload);
      expect(deserialized.addresses.isEmpty, isTrue);
    });

    test('should serialize and deserialize with a single address', () {
      final address = Address(
        ip: '192.168.1.1',
        port: 8333,
        services: 1,
        timestamp: 1609459200,
      );
      
      final message = AddrMessage([address]);
      final payload = message.payload();
      
      // 1 byte for count + 30 bytes for a single address
      expect(payload.length, equals(31));
      expect(payload[0], equals(1)); // Count = 1
      
      final deserialized = AddrMessage.deserialize(payload);
      expect(deserialized.addresses.length, equals(1));
      expect(deserialized.addresses[0].ip, equals('192.168.1.1'));
      expect(deserialized.addresses[0].port, equals(8333));
      expect(deserialized.addresses[0].services, equals(1));
      expect(deserialized.addresses[0].timestamp, equals(1609459200));
    });

    test('should serialize and deserialize with multiple addresses', () {
      final addresses = [
        Address(
          ip: '192.168.1.1',
          port: 8333,
          services: 1,
          timestamp: 1609459200,
        ),
        Address(
          ip: '10.0.0.1',
          port: 18333,
          services: 5,
          timestamp: 1609459300,
        ),
        Address(
          ip: '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
          port: 8333,
          services: 9,
          timestamp: 1609459400,
        ),
      ];
      
      final message = AddrMessage(addresses);
      final payload = message.payload();
      
      // 1 byte for count + 30 bytes for each address
      expect(payload.length, equals(1 + 30 * 3));
      expect(payload[0], equals(3)); // Count = 3
      
      final deserialized = AddrMessage.deserialize(payload);
      expect(deserialized.addresses.length, equals(3));
      
      expect(deserialized.addresses[0].ip, equals('192.168.1.1'));
      expect(deserialized.addresses[0].port, equals(8333));
      expect(deserialized.addresses[0].services, equals(1));
      expect(deserialized.addresses[0].timestamp, equals(1609459200));
      
      expect(deserialized.addresses[1].ip, equals('10.0.0.1'));
      expect(deserialized.addresses[1].port, equals(18333));
      expect(deserialized.addresses[1].services, equals(5));
      expect(deserialized.addresses[1].timestamp, equals(1609459300));
      
      expect(deserialized.addresses[2].ip, equals('2001:0db8:85a3:0000:0000:8a2e:0370:7334'));
      expect(deserialized.addresses[2].port, equals(8333));
      expect(deserialized.addresses[2].services, equals(9));
      expect(deserialized.addresses[2].timestamp, equals(1609459400));
    });

    test('should handle varying IP address formats', () {
      final addresses = [
        Address(
          ip: '192.168.1.1', // IPv4
          port: 8333,
          services: 1,
          timestamp: 1609459200,
        ),
        Address(
          ip: '2001:0db8:85a3:0000:0000:8a2e:0370:7334', // IPv6 full format
          port: 8333,
          services: 9,
          timestamp: 1609459400,
        ),
      ];
      
      final message = AddrMessage(addresses);
      final payload = message.payload();
      final deserialized = AddrMessage.deserialize(payload);
      
      expect(deserialized.addresses[0].ip, equals('192.168.1.1'));
      expect(deserialized.addresses[1].ip, equals('2001:0db8:85a3:0000:0000:8a2e:0370:7334'));
    });

    test('should handle larger number of addresses', () {
      // Create 100 addresses
      final addresses = List.generate(100, (index) => 
        Address(
          ip: '192.168.1.${index % 255}',
          port: 8333 + (index % 10),
          services: index % 5,
          timestamp: 1609459200 + index,
        )
      );
      
      final message = AddrMessage(addresses);
      final payload = message.payload();
      
      // For 100 addresses, the varint will be 1 byte, plus 30 bytes per address
      expect(payload.length, equals(1 + 30 * 100));
      
      final deserialized = AddrMessage.deserialize(payload);
      expect(deserialized.addresses.length, equals(100));
      
      // Check a few of the entries
      expect(deserialized.addresses[0].ip, equals('192.168.1.0'));
      expect(deserialized.addresses[0].timestamp, equals(1609459200));
      
      expect(deserialized.addresses[50].ip, equals('192.168.1.50'));
      expect(deserialized.addresses[50].timestamp, equals(1609459250));
      
      expect(deserialized.addresses[99].ip, equals('192.168.1.99'));
      expect(deserialized.addresses[99].timestamp, equals(1609459299));
    });

    test('should handle the compacted VarInt encoding for 253+ addresses', () {
      // Create 253 addresses (which requires 0xFD encoding for the varint)
      final addresses = List.generate(253, (index) => 
        Address(
          ip: '192.168.1.${index % 255}',
          port: 8333,
          services: 1,
          timestamp: 1609459200,
        )
      );
      
      final message = AddrMessage(addresses);
      final payload = message.payload();
      
      // For 253 addresses, the varint will be 3 bytes (0xFD + 2 byte value), plus 30 bytes per address
      expect(payload.length, equals(3 + 30 * 253));
      expect(payload[0], equals(0xFD)); // VarInt marker for 2-byte length
      expect(payload[1], equals(253)); // Lower byte of count
      expect(payload[2], equals(0));   // Upper byte of count
      
      final deserialized = AddrMessage.deserialize(payload);
      expect(deserialized.addresses.length, equals(253));
    });
  });
}