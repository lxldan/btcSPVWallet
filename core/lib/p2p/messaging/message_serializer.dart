import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/network.dart';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';
import 'dart:convert';

/// A serializer for Bitcoin P2P network messages.
/// 
/// Bitcoin messages follow this format:
/// - 4 bytes: Magic value indicating the network (mainnet, testnet, etc.)
/// - 12 bytes: ASCII command name (padded with nulls)
/// - 4 bytes: Payload size (little-endian)
/// - 4 bytes: Checksum (first 4 bytes of double SHA256 of payload)
/// - Variable bytes: The payload itself
class MessageSerializer {

  static final _currentNetwork = Network.mainnet;

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

  static Uint8List _createHeader(
  MessageCommand command,
  int payloadSize,
  Uint8List checksum,
) {
  final header = Uint8List(24);
  
  // Write magic bytes
  header.setRange(0, 4, _currentNetwork.magicBytes);
  
  // Write command name - строго 12 байт, с нулевым заполнением
  final commandName = command.name;
  final commandBytes = Uint8List(12); // Создаем буфер точно 12 байт
  
  // Копируем байты ASCII команды в буфер
  for (int i = 0; i < commandName.length && i < 12; i++) {
    commandBytes[i] = commandName.codeUnitAt(i);
  }
  // Остальные байты уже нулевые по умолчанию
  
  // Копируем командный буфер в заголовок
  header.setRange(4, 16, commandBytes);
  
  // Write payload size (4 bytes, little-endian)
  _writeUint32LE(header, 16, payloadSize);
  
  // Write checksum (4 bytes)
  header.setRange(20, 24, checksum);
  
  return header;
}
  /// Calculates the checksum for a payload.
  /// 
  /// The checksum is the first 4 bytes of a double SHA256 hash.
  static Uint8List _calculateChecksum(Uint8List payload) {
    final hash1 = sha256.convert(payload).bytes;
    final hash2 = sha256.convert(hash1).bytes;
    return Uint8List.fromList(hash2.sublist(0, 4));
  }
    
  /// Writes a uint32 to bytes in little-endian format.
  static void _writeUint32LE(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xFF;
    bytes[offset + 1] = (value >> 8) & 0xFF;
    bytes[offset + 2] = (value >> 16) & 0xFF;
    bytes[offset + 3] = (value >> 24) & 0xFF;
  }
}