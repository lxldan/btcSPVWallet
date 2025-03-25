import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/messages/getheaders_message.dart';

void main() {
  group('GetHeadersMessage', () {
    test('constructor creates valid message', () {
      final version = 70015;
      final blockLocatorHashes = [
        Uint8List(32),  // Empty hash for simplicity
        Uint8List.fromList(List.filled(32, 1)),
      ];
      final hashStop = Uint8List.fromList(List.filled(32, 2));

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

    test('serialization and deserialization work correctly', () {
      final original = GetHeadersMessage(
        version: 70015,
        blockLocatorHashes: [
          Uint8List.fromList(List.filled(32, 1)),
          Uint8List.fromList(List.filled(32, 2)),
        ],
        hashStop: Uint8List.fromList(List.filled(32, 3)),
      );

      final serialized = original.payload();
      final deserialized = GetHeadersMessage.deserialize(serialized);

      expect(deserialized.version, equals(original.version));
      expect(deserialized.blockLocatorHashes, equals(original.blockLocatorHashes));
      expect(deserialized.hashStop, equals(original.hashStop));
    });

    test('handles empty block locator hashes', () {
      final original = GetHeadersMessage(
        version: 70015,
        blockLocatorHashes: [],
        hashStop: Uint8List.fromList(List.filled(32, 1)),
      );

      final serialized = original.payload();
      final deserialized = GetHeadersMessage.deserialize(serialized);

      expect(deserialized.blockLocatorHashes, isEmpty);
      expect(deserialized.hashStop, equals(original.hashStop));
    });

    test('handles large number of block locator hashes', () {
      final blockLocatorHashes = List.generate(
        1000,
        (i) => Uint8List.fromList(List.filled(32, i % 256)),
      );

      final original = GetHeadersMessage(
        version: 70015,
        blockLocatorHashes: blockLocatorHashes,
        hashStop: Uint8List.fromList(List.filled(32, 1)),
      );

      final serialized = original.payload();
      final deserialized = GetHeadersMessage.deserialize(serialized);

      expect(deserialized.blockLocatorHashes.length, equals(1000));
      expect(deserialized.blockLocatorHashes, equals(original.blockLocatorHashes));
    });
  });
}
