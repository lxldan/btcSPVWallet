import 'package:collection/collection.dart';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/messages/addr_message.dart';
import 'package:core/p2p/messaging/messages/cfilter_message.dart';
import 'package:core/p2p/messaging/messages/headers_message.dart';
import 'package:core/p2p/messaging/messages/ping_message.dart';
import 'package:core/p2p/messaging/messages/verack_message.dart';
import 'package:core/p2p/messaging/messages/version_message.dart';
import 'package:core/p2p/messaging/network.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data';
import 'dart:convert';

class MessageDeserializer {

  static final _logger = Logger();
  static final _currentNetwork = Network.mainnet;

  // Maximum allowed payload size (consensus rule)
  static const int _maxPayloadSize = 32 * 1024 * 1024; // 32 MB

  /// Deserializes a byte array into a [Message].
  /// 
  /// Throws [FormatException] if the message format is invalid.
  static Message? deserializeMessage(Uint8List data) {
    
    // Check minimum message length (24 bytes for header)
    if (data.length < 24) {
      throw FormatException(
        'Message too short: must be at least 24 bytes (got ${data.length})'
      );
    }

    // Verify magic bytes
    if (!verifyMagicBytes(data.sublist(0, 4))) {
      throw FormatException('Invalid magic bytes');
    }

    // Extract command
    final commandBytes = data.sublist(4, 16);
    final commandName = utf8.decode(
      commandBytes.takeWhile((byte) => byte != 0).toList(),
      allowMalformed: false
    );
    
    final command = MessageCommand.values.firstWhereOrNull(
      (c) => c.name == commandName
    ) ?? MessageCommand.unknown;

    // Extract payload size
    final payloadSize = _readUint32LE(data, 16);
    
    // Validate payload size
    if (payloadSize > _maxPayloadSize) {
      throw FormatException('Payload size exceeds maximum allowed (got $payloadSize, max $_maxPayloadSize)');
    }
    
    if (payloadSize + 24 > data.length) {
      throw FormatException('Incomplete message: expected ${payloadSize + 24} bytes, got ${data.length}');
    }

    // Extract and verify checksum
    final receivedChecksum = data.sublist(20, 24);
    final payload = data.sublist(24, 24 + payloadSize);
    final calculatedChecksum = _calculateChecksum(payload);
    
    if (!const ListEquality<int>().equals(receivedChecksum, calculatedChecksum)) {
      throw FormatException('Invalid checksum');
    }
    
    try {
      return _generateMessage(command, payload);
    } catch (e) {
      _logger.e('Error generating message for command: ${command.name}');
      throw FormatException('Failed to parse payload for command: ${command.name}: $e');
    }
  }

  /// Calculates the checksum for a payload.
  /// 
  /// The checksum is the first 4 bytes of a double SHA256 hash.
  static Uint8List _calculateChecksum(Uint8List payload) {
    final hash1 = sha256.convert(payload).bytes;
    final hash2 = sha256.convert(hash1).bytes;
    return Uint8List.fromList(hash2.sublist(0, 4));
  }

  /// Verifies that the provided bytes match the expected magic bytes.
  static bool verifyMagicBytes(Uint8List bytes) {
    if (bytes.length != 4) return false;
    
    final magicToCheck = _currentNetwork.magicBytes;
    for (int i = 0; i < 4; i++) {
      if (bytes[i] != magicToCheck[i]) return false;
    }
    return true;
  }

  /// Reads a uint32 from bytes in little-endian format.
  static int _readUint32LE(Uint8List bytes, int offset) {
    return bytes[offset] |
           (bytes[offset + 1] << 8) |
           (bytes[offset + 2] << 16) |
           (bytes[offset + 3] << 24);
  }

  /// Creates a message instance based on the command type.
  static Message? _generateMessage(
    MessageCommand command, 
    Uint8List payload
  ) {
    switch (command) {
      case MessageCommand.version:
        return VersionMessage.deserialize(payload);
      case MessageCommand.addr:
        return AddrMessage.deserialize(payload);
      case MessageCommand.headers:
        return HeadersMessage.deserialize(payload);
      case MessageCommand.verack:
        return VerackMessage();
      case MessageCommand.ping:
        return PingMessage.deserialize(payload);
      case MessageCommand.pong:
        return PingMessage.deserialize(payload);
      case MessageCommand.cfilter:
        return CFilterMessage.deserialize(payload);
      case MessageCommand.unknown:
        _logger.e('Unknown message command received');
        return null;
      default:
        _logger.e(
          'MessageSerializer error: Unhandled message command: ${command.name}'
        );
        return null;
    }
  }
}