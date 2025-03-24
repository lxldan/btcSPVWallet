import 'dart:typed_data';
import 'package:core/blockchain/block_header.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/messages/headers_message.dart';
import 'package:test/test.dart';

void main() {
  group('HeadersMessage', () {
    late BlockHeader testHeader1;
    late BlockHeader testHeader2;
    late BlockHeader testHeader3;
    
    setUp(() {
      // Setup test block headers with different values
      testHeader1 = BlockHeader(
        version: 1,
        prevBlock: Uint8List.fromList(List.filled(32, 1)),
        merkleRoot: Uint8List.fromList(List.filled(32, 2)),
        timestamp: 1231006505,
        bits: 0x1d00ffff,
        nonce: 2083236893,
      );
      
      testHeader2 = BlockHeader(
        version: 2,
        prevBlock: Uint8List.fromList(List.filled(32, 3)),
        merkleRoot: Uint8List.fromList(List.filled(32, 4)),
        timestamp: 1231006506,
        bits: 0x1d00ffff,
        nonce: 2083236894,
      );
      
      testHeader3 = BlockHeader(
        version: 3,
        prevBlock: Uint8List.fromList(List.filled(32, 5)),
        merkleRoot: Uint8List.fromList(List.filled(32, 6)),
        timestamp: 1231006507,
        bits: 0x1d00ffff,
        nonce: 2083236895,
      );
    });
    
    test('constructor should set headers property', () {
      final headers = [testHeader1, testHeader2];
      final message = HeadersMessage(headers);
      
      expect(message.headers, equals(headers));
      expect(message.command, equals(MessageCommand.headers));
    });
    
    test('payload() should correctly serialize small number of headers', () {
      final headers = [testHeader1, testHeader2];
      final message = HeadersMessage(headers);
      
      final payload = message.payload();
      
      // Check that payload starts with the count (2 headers)
      expect(payload[0], equals(2)); 
      
      // Total size should be: 1 byte (count) + 2 * (80 bytes header + 1 byte txn count)
      expect(payload.length, equals(1 + 2 * 81));
    });
    
    test('payload() should use compact format for larger count', () {
      // Create a list of 300 headers (exceeds 252 which needs compact format)
      final manyHeaders = List.generate(300, (i) => i % 2 == 0 ? testHeader1 : testHeader2);
      final message = HeadersMessage(manyHeaders);
      
      final payload = message.payload();
      
      // Compact format should start with 0xfd followed by 2-byte little-endian value
      expect(payload[0], equals(0xfd));
      expect(payload[1], equals(300 & 0xff)); // Lower byte
      expect(payload[2], equals((300 >> 8) & 0xff)); // Upper byte
      
      // Total size: 3 bytes (compact count) + 300 * (80 bytes header + 1 byte txn count)
      expect(payload.length, equals(3 + 300 * 81));
    });
    
    test('deserialize() should correctly parse payload', () {
      final originalHeaders = [testHeader1, testHeader2, testHeader3];
      final originalMessage = HeadersMessage(originalHeaders);
      final payload = originalMessage.payload();
      
      final deserializedMessage = HeadersMessage.deserialize(payload);
      
      expect(deserializedMessage.headers.length, equals(3));
      expect(deserializedMessage.command, equals(MessageCommand.headers));
      
      // Verify the headers were correctly deserialized
      for (var i = 0; i < originalHeaders.length; i++) {
        expect(deserializedMessage.headers[i].version, equals(originalHeaders[i].version));
        expect(deserializedMessage.headers[i].prevBlock, equals(originalHeaders[i].prevBlock));
        expect(deserializedMessage.headers[i].merkleRoot, equals(originalHeaders[i].merkleRoot));
        expect(deserializedMessage.headers[i].timestamp, equals(originalHeaders[i].timestamp));
        expect(deserializedMessage.headers[i].bits, equals(originalHeaders[i].bits));
        expect(deserializedMessage.headers[i].nonce, equals(originalHeaders[i].nonce));
      }
    });
    
    test('round-trip serialization preserves data', () {
      final originalHeaders = [testHeader1, testHeader2, testHeader3];
      final originalMessage = HeadersMessage(originalHeaders);
      
      final payload = originalMessage.payload();
      final deserializedMessage = HeadersMessage.deserialize(payload);
      
      expect(deserializedMessage.headers.length, equals(originalHeaders.length));
      
      for (var i = 0; i < originalHeaders.length; i++) {
        // Compare serialized representation to ensure they're identical
        expect(
          deserializedMessage.headers[i].serialize(),
          equals(originalHeaders[i].serialize())
        );
      }
    });
    
    test('handles empty headers list', () {
      final emptyMessage = HeadersMessage([]);
      final payload = emptyMessage.payload();
      
      expect(payload.length, equals(1)); // Just the count byte (0)
      expect(payload[0], equals(0)); // Zero headers
      
      final deserializedMessage = HeadersMessage.deserialize(payload);
      expect(deserializedMessage.headers, isEmpty);
    });
    
    test('deserialize handles compact format for header count', () {
      // Create message with compact format (0xfd prefix)
      final buffer = ByteData(4 + 81); // 3 bytes count + 1 header
      buffer.setUint8(0, 0xfd);
      buffer.setUint16(1, 1, Endian.little); // 1 header, but using compact format
      
      // Add one header
      buffer.buffer.asUint8List(3, 80).setAll(0, testHeader1.serialize());
      buffer.setUint8(3 + 80, 0); // Tx count of 0
      
      final payload = buffer.buffer.asUint8List(0, 4 + 81 - 1);
      final message = HeadersMessage.deserialize(payload);
      
      expect(message.headers.length, equals(1));
      expect(message.headers.first.version, equals(testHeader1.version));
    });
    
    test('correctly handles very large compact format (0xfe)', () {
      // This is a simulation test since creating thousands of headers would be inefficient
      final buffer = ByteData(6 + 81); // 5 bytes count + 1 header (simulation)
      buffer.setUint8(0, 0xfe);
      buffer.setUint32(1, 1, Endian.little); // 1 header using 0xfe format
      
      // Add one header
      buffer.buffer.asUint8List(5, 80).setAll(0, testHeader1.serialize());
      buffer.setUint8(5 + 80, 0); // Tx count of 0
      
      final payload = buffer.buffer.asUint8List(0, 6 + 81 - 1);
      final message = HeadersMessage.deserialize(payload);
      
      expect(message.headers.length, equals(1));
    });
  });
}
