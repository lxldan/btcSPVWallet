import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/messages/addr_message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/messages/headers_message.dart';
import 'package:core/p2p/messaging/messages/version_message.dart';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:logger/logger.dart';

/// Enum representing different Bitcoin networks
enum BitcoinNetwork {
  mainnet,
  testnet,
  regtest,
  signet
}

/// A serializer for Bitcoin P2P network messages.
/// 
/// Bitcoin messages follow this format:
/// - 4 bytes: Magic value indicating the network (mainnet, testnet, etc.)
/// - 12 bytes: ASCII command name (padded with nulls)
/// - 4 bytes: Payload size (little-endian)
/// - 4 bytes: Checksum (first 4 bytes of double SHA256 of payload)
/// - Variable bytes: The payload itself
class MessageSerializer {

  // mainnet magic bytes
  static final Uint8List _magicBytes = Uint8List.fromList([
    0xf9, 
    0xbe, 
    0xb4, 
    0xd9
  ]);

  // testnet magic bytes
  static final Uint8List _testnetMagicBytes = Uint8List.fromList([
    0x0b,
    0x11,
    0x09,
    0x07
  ]);
  
  // regtest magic bytes
  static final Uint8List _regtestMagicBytes = Uint8List.fromList([
    0xfa,
    0xbf,
    0xb5,
    0xda
  ]);
  
  // signet magic bytes
  static final Uint8List _signetMagicBytes = Uint8List.fromList([
    0x0a,
    0x03,
    0xcf,
    0x40
  ]);

  // Current network (defaults to mainnet)
  static BitcoinNetwork _currentNetwork = BitcoinNetwork.mainnet;

  // Maximum allowed payload size (consensus rule)
  static const int _maxPayloadSize = 32 * 1024 * 1024; // 32 MB
  // Logger instance
  static final _logger = Logger();

  /// Sets the current Bitcoin network to use for serialization/deserialization
  static void setNetwork(BitcoinNetwork network) {
    _currentNetwork = network;
  }

  /// Gets the current active magic bytes based on network setting
  static Uint8List get currentMagicBytes {
    switch (_currentNetwork) {
      case BitcoinNetwork.mainnet:
        return _magicBytes;
      case BitcoinNetwork.testnet:
        return _testnetMagicBytes;
      case BitcoinNetwork.regtest:
        return _regtestMagicBytes;
      case BitcoinNetwork.signet:
        return _signetMagicBytes;
    }
  }

  /// Serializes a [Message] into a byte array.
  static Uint8List serializeMessage(Message message) {
    final payload = message.payload();
    final checksum = _calculateChecksum(payload);
    final header = _createHeader(
      message.command, 
      payload.length, 
      checksum
    );
    
    // Combine header and payload
    final result = Uint8List(header.length + payload.length);
    result.setRange(0, header.length, header);
    result.setRange(header.length, result.length, payload);
    return result;
  }

  /// Identifies the command type of a serialized message without fully deserializing it
  static MessageCommand identifyCommand(Uint8List data) {
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
    
    return MessageCommand.values.firstWhereOrNull(
      (c) => c.name == commandName
    ) ?? MessageCommand.unknown;
  }

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

  /// Creates a message instance based on the command type.
  static Message? _generateMessage(MessageCommand command, Uint8List payload) {
    switch (command) {
      case MessageCommand.version:
        return VersionMessage.deserialize(payload);
      case MessageCommand.addr:
        return AddrMessage.deserialize(payload);
      case MessageCommand.headers:
        return HeadersMessage.deserialize(payload);
      case MessageCommand.unknown:
        _logger.i('Unknown message command received');
        return null;
      default:
        _logger.i('Unhandled message command: ${command.name}');
        return null;
    }
  }

  /// Creates the message header.
  static Uint8List _createHeader(
    MessageCommand command, 
    int payloadSize, 
    Uint8List checksum
  ) {
    final result = Uint8List(24); // Header is always 24 bytes
    
    // Copy magic bytes
    result.setRange(0, 4, currentMagicBytes);
    
    // Copy command name (padded with zeros)
    final commandBytes = utf8.encode(command.name);
    result.setRange(4, 4 + commandBytes.length, commandBytes);
    // Padding is already zeros (Uint8List initializes to zeros)
    
    // Set payload size (little endian)
    _writeUint32LE(result, 16, payloadSize);
    
    // Set checksum
    result.setRange(20, 24, checksum);
    
    return result;
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
    
    final magicToCheck = currentMagicBytes;
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
  
  /// Writes a uint32 to bytes in little-endian format.
  static void _writeUint32LE(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
    bytes[offset + 2] = (value >> 16) & 0xFF;
    bytes[offset + 3] = (value >> 24) & 0xFF;
  }
}