import 'package:core/extensions.dart';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/network.dart';
import 'dart:typed_data';

/// A serializer for Bitcoin P2P network messages.
/// 
/// Bitcoin messages follow this format:
/// - 4 bytes: Magic value indicating the network (mainnet, testnet, etc.)
/// - 12 bytes: ASCII command name (padded with nulls)
/// - 4 bytes: Payload size (little-endian)
/// - 4 bytes: Checksum (first 4 bytes of double SHA256 of payload)
/// - Variable bytes: The payload itself
class MessageSerializer {
  
  static const _currentNetwork = Network.mainnet;
  static const int _magicSize = 4;
  static const int _commandSize = 12;
  static const int _lengthSize = 4;
  static const int _checksumSize = 4;
  static const int _headerSize = _magicSize + _commandSize + _lengthSize + _checksumSize;

  /// Serializes a [Message] into a byte array.
  static Uint8List serializeMessage(Message message) {
    final payload = message.payload();
    final checksum = calculateChecksum(payload);
    final header = _createHeader(
      message.command, 
      payload.length, 
      checksum,
    );
    
    // Combine header and payload
    final result = Uint8List(header.length + payload.length);
    result.setRange(0, header.length, header);
    result.setRange(header.length, result.length, payload);
    return result;
  }

  static Uint8List _createHeader(
    MessageCommand command,
    int payloadLength,
    Uint8List checksum,
  ) {
    final magicBytes = _currentNetwork.magicBytes;
    if (magicBytes.length != _magicSize) {
      throw Exception('Magic bytes must be exactly $_magicSize bytes');
    }
    if (checksum.length != _checksumSize) {
      throw Exception('Checksum must be exactly $_checksumSize bytes');
    }
    final commandName = command.name;
    if (commandName.length > _commandSize) {
      throw Exception('Command length exceeds $_commandSize bytes');
    }

    final header = ByteData(_headerSize);
    final headerBytes = header.buffer.asUint8List();
    headerBytes.setRange(0, _magicSize, magicBytes);

    for (int i = 0; i < commandName.length && i < _commandSize; i++) {
      header.setUint8(_magicSize + i, commandName.codeUnitAt(i));
    }

    header.setUint32(
      _magicSize + _commandSize, payloadLength, Endian.little
    );

    headerBytes.setRange(
      _magicSize + _commandSize + _lengthSize,
      _magicSize + _commandSize + _lengthSize + _checksumSize,
      checksum,
    );

    return headerBytes;
  }
}