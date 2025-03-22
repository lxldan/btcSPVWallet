import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:core/p2p/messaging/messages/getheaders_message.dart';
import 'package:core/p2p/messaging/message_command.dart';

void main() {
  group('GetHeadersMessage', () {

    // Helper function for readability
    Uint8List createHash(int value) {
      final hash = Uint8List(32);
      hash[0] = value;
      return hash;
    }
    
    test('constructor should create instance with correct properties', () {
      final version = 70015;
      final blockLocatorHashes = [createHash(1), createHash(2)];
      final hashStop = createHash(0);
      
      final message = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop
      );
      
      expect(message.version, equals(version));
      expect(message.blockLocatorHashes, equals(blockLocatorHashes));
      expect(message.hashStop, equals(hashStop));
    });
    
    test('command getter should return getheaders', () {
      final message = GetHeadersMessage(
        version: 1,
        blockLocatorHashes: [createHash(1)],
        hashStop: createHash(0)
      );
      
      expect(message.command, equals(MessageCommand.getheaders));
    });
    
    test('payload with single block locator hash', () {
      final version = 1;
      final blockLocatorHashes = [createHash(1)];
      final hashStop = createHash(0);
      
      final message = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop
      );
      
      final payload = message.payload();
      
      // Expected format:
      // Version (4 bytes) + Count (1 byte) + Hash (32 bytes) + Stop hash (32 bytes)
      expect(payload.length, equals(4 + 1 + 32 + 32));
      
      // Check version (little endian)
      final payloadData = ByteData.view(payload.buffer);
      expect(payloadData.getUint32(0, Endian.little), equals(version));
      
      // Check count
      expect(payload[4], equals(1)); // 1 hash
      
      // Check hash (should be reversed in payload)
      expect(payload[5], equals(0)); // Last byte of reversed hash
      expect(payload[5 + 31], equals(1)); // First byte of reversed hash
      
      // Check stop hash
      expect(payload[5 + 32], equals(0)); // Last byte of reversed hash
      // All bytes should be 0 in this case
    });
    
    test('payload with multiple block locator hashes', () {
      final version = 1;
      final blockLocatorHashes = [createHash(1), createHash(2), createHash(3)];
      final hashStop = createHash(0);
      
      final message = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop
      );
      
      final payload = message.payload();
      
      // Expected: Version (4) + Count (1) + 3 Hashes (32*3) + Stop hash (32)
      expect(payload.length, equals(4 + 1 + 32*3 + 32));
      
      // Check count
      expect(payload[4], equals(3)); // 3 hashes
      
      // Check first hash
      expect(payload[5 + 31], equals(1)); // First hash, first byte (reversed)
      
      // Check second hash
      expect(payload[5 + 32 + 31], equals(2)); // Second hash, first byte (reversed)
      
      // Check third hash
      expect(payload[5 + 64 + 31], equals(3)); // Third hash, first byte (reversed)
    });
    
    test('payload encodes count correctly for different sizes', () {
      // Test small count (< 0xFD)
      {
        final message = GetHeadersMessage(
          version: 1,
          blockLocatorHashes: List.generate(10, (i) => createHash(i)),
          hashStop: createHash(0)
        );
        
        final payload = message.payload();
        expect(payload[4], equals(10)); // Direct byte value
      }
      
      // Test medium count (>= 0xFD, <= 0xFFFF)
      // For this test we'll mock the count rather than creating thousands of hashes
      {
        final message = GetHeadersMessage(
          version: 1,
          blockLocatorHashes: List.generate(2, (i) => createHash(i)),
          hashStop: createHash(0)
        );
        
        // Hack the count for testing the encoding - the actual data doesn't matter
        // This is simulating having 1000 hashes (0x03E8) which should use 3 bytes encoding
        final buffer = ByteData(4 + 3 + 2*32 + 32);
        buffer.setUint32(0, 1, Endian.little);
        buffer.setUint8(4, 0xFD); // Marker for 2-byte integer
        buffer.setUint16(5, 1000, Endian.little); // Count as uint16
        
        // The rest of the payload doesn't matter for this test
        
        // Now test that GetHeadersMessage produces the right encoding
        final realMessage = GetHeadersMessage(
          version: 1,
          blockLocatorHashes: List.generate(1000, (i) => createHash(i % 256)),
          hashStop: createHash(0)
        );
        
        final realPayload = realMessage.payload();
        expect(realPayload[4], equals(0xFD)); // Marker for 2-byte integer
        expect(realPayload[5], equals(0xE8)); // 1000 & 0xFF
        expect(realPayload[6], equals(0x03)); // (1000 >> 8) & 0xFF
      }
    });
  });
}
