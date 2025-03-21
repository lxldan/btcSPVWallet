import 'dart:typed_data';
import 'package:core/p2p/messaging/messages/adress.dart';
import 'package:test/test.dart';
/*
 Encapsulated network IP address uses in Addr message

Structure:
    Timestamp:          4 bytes - Unix time (when the address was last seen; available since protocol version 31402)
    Services:           8 bytes - Bitmask of supported services (e.g., NODE_NETWORK)
    IP Address:         16 bytes - The IP address (IPv4 addresses are represented as IPv4-mapped IPv6)
    Port:               2 bytes - The port number in network byte order (typically 8333)
*/
void main() {
  group('Address', () {
    test('should create a PeerAddress object with IPv4', () {
      final address = Address(
        ip: '192.168.1.1',
        port: 8333,
        services: 1,
        timestamp: 1609459200,
      );
      
      expect(address.ip, equals('192.168.1.1'));
      expect(address.port, equals(8333));
      expect(address.services, equals(1));
      expect(address.timestamp, equals(1609459200));
    });
    
    test('should create a PeerAddress object with IPv6', () {
      final address = Address(
        ip: '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
        port: 8333,
        services: 1,
        timestamp: 1609459200,
      );
      
      expect(address.ip, equals('2001:0db8:85a3:0000:0000:8a2e:0370:7334'));
      expect(address.port, equals(8333));
      expect(address.services, equals(1));
      expect(address.timestamp, equals(1609459200));
    });
    
    test('should serialize and deserialize IPv4 address correctly', () {
      final originalAddress = Address(
        ip: '192.168.1.1',
        port: 8333,
        services: 1,
        timestamp: 1609459200,
      );
      
      final serialized = originalAddress.serialize();
      expect(serialized.length, equals(30));
      
      final deserialized = Address.deserialize(ByteData.view(serialized.buffer), 0);
      
      expect(deserialized.ip, equals(originalAddress.ip));
      expect(deserialized.port, equals(originalAddress.port));
      expect(deserialized.services, equals(originalAddress.services));
      expect(deserialized.timestamp, equals(originalAddress.timestamp));
    });
    
    test('should serialize and deserialize IPv6 address correctly', () {
      final originalAddress = Address(
        ip: '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
        port: 8333,
        services: 1,
        timestamp: 1609459200,
      );
      
      final serialized = originalAddress.serialize();
      expect(serialized.length, equals(30));
      
      final deserialized = Address.deserialize(ByteData.view(serialized.buffer), 0);
      
      expect(deserialized.ip, equals(originalAddress.ip));
      expect(deserialized.port, equals(originalAddress.port));
      expect(deserialized.services, equals(originalAddress.services));
      expect(deserialized.timestamp, equals(originalAddress.timestamp));
    });
    
    test('should handle offset when deserializing', () {
      final address = Address(
        ip: '192.168.1.1',
        port: 8333,
        services: 1,
        timestamp: 1609459200,
      );
      
      final serialized = address.serialize();
      
      // Create a buffer with some prefix data
      final buffer = Uint8List(40);
      for (var i = 0; i < 10; i++) {
        buffer[i] = 0xFF;
      }
      
      // Copy serialized data starting at offset 10
      buffer.setRange(10, 10 + serialized.length, serialized);
      
      final deserialized = Address.deserialize(ByteData.view(buffer.buffer), 10);
      
      expect(deserialized.ip, equals(address.ip));
      expect(deserialized.port, equals(address.port));
      expect(deserialized.services, equals(address.services));
      expect(deserialized.timestamp, equals(address.timestamp));
    });
    
    test('should throw FormatException for invalid IP address', () {
      final address = Address(
        ip: 'invalid-ip',
        port: 8333,
        services: 1,
        timestamp: 1609459200,
      );
      
      expect(() => address.serialize(), throwsA(isA<FormatException>()));
    });
    
    test('should handle large service values', () {
      final address = Address(
        ip: '192.168.1.1',
        port: 8333,
        services: 0xFFFFFFFFFFFFFFFF, // Maximum uint64 value
        timestamp: 1609459200,
      );
      
      final serialized = address.serialize();
      final deserialized = Address.deserialize(ByteData.view(serialized.buffer), 0);
      
      expect(deserialized.services, equals(address.services));
    });
  });
}
