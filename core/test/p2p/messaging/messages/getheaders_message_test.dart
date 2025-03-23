import 'dart:typed_data';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/messages/getheaders_message.dart';
import 'package:test/test.dart';

void main() {
  group('GetHeadersMessage', () {
    final version = 70015;
    final hashStop = Uint8List.fromList(List.generate(32, (index) => 0xFF));
    
    Uint8List createRandomHash() {
      return Uint8List.fromList(List.generate(32, (index) => index % 256));
    }
    
    test('constructor creates a valid message', () {
      final blockLocatorHashes = [createRandomHash()];
      final message = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop,
      );
      
      expect(message.version, equals(version));
      expect(message.blockLocatorHashes, equals(blockLocatorHashes));
      expect(message.hashStop, equals(hashStop));
      expect(message.command, equals(MessageCommand.getheaders));
    });
    
    test('payload with a single block locator hash', () {
      final blockLocatorHashes = [createRandomHash()];
      final message = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop,
      );
      
      final payload = message.payload();
      
      // Calculate expected length: 4 (version) + 1 (count) + 32 (hash) + 32 (hashStop)
      final expectedLength = 4 + 1 + 32 + 32;
      expect(payload.length, equals(expectedLength));
      
      // Check header structure
      final buffer = ByteData.sublistView(payload);
      expect(buffer.getUint32(0, Endian.little), equals(version));
      expect(buffer.getUint8(4), equals(1)); // Single hash count
      
      // Verify block hash is reversed
      final reversedHash = Uint8List.fromList(blockLocatorHashes[0].reversed.toList());
      for (var i = 0; i < 32; i++) {
        expect(payload[5 + i], equals(reversedHash[i]));
      }
      
      // Verify hashStop is reversed
      final reversedHashStop = Uint8List.fromList(hashStop.reversed.toList());
      for (var i = 0; i < 32; i++) {
        expect(payload[5 + 32 + i], equals(reversedHashStop[i]));
      }
    });
    
    test('payload with multiple block locator hashes', () {
      final blockLocatorHashes = List.generate(10, (_) => createRandomHash());
      final message = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop,
      );
      
      final payload = message.payload();
      
      // Calculate expected length: 4 (version) + 1 (count) + 10*32 (hashes) + 32 (hashStop)
      final expectedLength = 4 + 1 + 10*32 + 32;
      expect(payload.length, equals(expectedLength));
      
      final buffer = ByteData.sublistView(payload);
      expect(buffer.getUint32(0, Endian.little), equals(version));
      expect(buffer.getUint8(4), equals(10)); // 10 hashes
      
      // Verify all block hashes are reversed
      for (var hashIndex = 0; hashIndex < blockLocatorHashes.length; hashIndex++) {
        final reversedHash = Uint8List.fromList(blockLocatorHashes[hashIndex].reversed.toList());
        for (var i = 0; i < 32; i++) {
          expect(payload[5 + (hashIndex * 32) + i], equals(reversedHash[i]));
        }
      }
    });
    
    test('payload with count requiring compact size uint (0xfd format)', () {
      final blockLocatorHashes = List.generate(253, (_) => createRandomHash());
      final message = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop,
      );
      
      final payload = message.payload();
      
      // Calculate expected length: 4 (version) + 3 (count prefix + value) + 253*32 (hashes) + 32 (hashStop)
      final expectedLength = 4 + 3 + 253*32 + 32;
      expect(payload.length, equals(expectedLength));
      
      final buffer = ByteData.sublistView(payload);
      expect(buffer.getUint32(0, Endian.little), equals(version));
      expect(buffer.getUint8(4), equals(0xfd)); // Compact size uint marker
      expect(buffer.getUint16(5, Endian.little), equals(253)); // Hash count
    });
    
    test('payload with count requiring compact size uint (0xfe format)', () {
      // Testing with a smaller number to avoid memory issues in tests
      final blockLocatorHashes = List.generate(70000, (_) => createRandomHash());
      final message = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop,
      );
      
      final payload = message.payload();
      
      // Calculate expected length: 4 (version) + 5 (count prefix + value) + 70000*32 (hashes) + 32 (hashStop)
      final expectedLength = 4 + 5 + 70000*32 + 32;
      expect(payload.length, equals(expectedLength));
      
      final buffer = ByteData.sublistView(payload);
      expect(buffer.getUint32(0, Endian.little), equals(version));
      expect(buffer.getUint8(4), equals(0xfe)); // Compact size uint marker
      expect(buffer.getUint32(5, Endian.little), equals(70000)); // Hash count
    });
    
    // Note: We're skipping the 0xFF test case as it would require generating an extremely large payload
    
    test('payload with no block locator hashes', () {
      final blockLocatorHashes = <Uint8List>[];
      final message = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop,
      );
      
      final payload = message.payload();
      
      // Calculate expected length: 4 (version) + 1 (count) + 32 (hashStop)
      final expectedLength = 4 + 1 + 32;
      expect(payload.length, equals(expectedLength));
      
      final buffer = ByteData.sublistView(payload);
      expect(buffer.getUint32(0, Endian.little), equals(version));
      expect(buffer.getUint8(4), equals(0)); // Zero hashes
    });
    
    test('deserialize correctly parses a serialized payload', () {
      // Create a message and serialize it
      final blockLocatorHashes = List.generate(3, (_) => createRandomHash());
      final originalMessage = GetHeadersMessage(
        version: version,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: hashStop,
      );
      
      final payload = originalMessage.payload();
      
      // Now deserialize the payload back to a message
      final deserializedMessage = GetHeadersMessage.deserialize(payload);
      
      // Check if the deserialized message matches the original
      expect(deserializedMessage.version, equals(originalMessage.version));
      expect(deserializedMessage.blockLocatorHashes.length, equals(originalMessage.blockLocatorHashes.length));
      
      // Compare each hash
      for (var i = 0; i < blockLocatorHashes.length; i++) {
        expect(
          deserializedMessage.blockLocatorHashes[i], 
          equals(originalMessage.blockLocatorHashes[i])
        );
      }
      
      expect(deserializedMessage.hashStop, equals(originalMessage.hashStop));
    });
    
    test('roundtrip serialization with various hash counts', () {
      for (final hashCount in [0, 1, 10, 100]) {
        final blockLocatorHashes = List.generate(hashCount, (_) => createRandomHash());
        final originalMessage = GetHeadersMessage(
          version: version,
          blockLocatorHashes: blockLocatorHashes,
          hashStop: hashStop,
        );
        
        final payload = originalMessage.payload();
        final deserializedMessage = GetHeadersMessage.deserialize(payload);
        
        expect(deserializedMessage.version, equals(originalMessage.version));
        expect(deserializedMessage.blockLocatorHashes.length, equals(hashCount));
        expect(deserializedMessage.hashStop, equals(originalMessage.hashStop));
      }
    });
  });
}
