import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_deserializer.dart';
import 'dart:typed_data';

class MessageParser {

  final _buffer = BytesBuilder();
  final List<Message> _parsedMessages = [];
  static final _magicBytes = Uint8List.fromList([0xf9, 0xbe, 0xb4, 0xd9]); 

  void processData(Uint8List data) {
    _buffer.add(data);
    _tryParseMessages();
  }

  List<Message> takeMessages() {
    final messages = List<Message>.from(_parsedMessages);
    _parsedMessages.clear();
    return messages;
  }

  _tryParseMessages() {
    var bufferBytes = _buffer.toBytes();

    while (bufferBytes.length >= 24) {
      if (!_magicBytes.every((b) => bufferBytes[_magicBytes.indexOf(b)] == b)) {
        final magicIndex = _findMagicBytes(bufferBytes);
        if (magicIndex == -1) {
          _buffer.clear();
          return;
        }
        bufferBytes = bufferBytes.sublist(magicIndex);
        _buffer.clear();
        _buffer.add(bufferBytes);
      }

      final payloadSize = _readUint32LE(bufferBytes, 16);
      final totalLength = 24 + payloadSize;

      if (bufferBytes.length < totalLength) {
        print("Waiting for more data: expected $totalLength bytes, got ${bufferBytes.length}");
        return;
      }

      final messageBytes = bufferBytes.sublist(0, totalLength);
      bufferBytes = bufferBytes.sublist(totalLength);
      _buffer.clear();
      _buffer.add(bufferBytes);

      try {
        final message = MessageDeserializer.deserializeMessage(messageBytes);
        if (message != null) {
          _parsedMessages.add(message);
          print("Parsed message: ${message.command}");
        }
      } catch (e) {
        print("Error parsing message: $e");
      }
    }
  }

  int _findMagicBytes(Uint8List data) {
    for (int i = 0; i < data.length - 3; i++) {
      if (data[i] == _magicBytes[0] &&
          data[i + 1] == _magicBytes[1] &&
          data[i + 2] == _magicBytes[2] &&
          data[i + 3] == _magicBytes[3]) {
        return i;
      }
    }
    return -1;
  }

  int _readUint32LE(Uint8List bytes, int offset) {
    return bytes[offset] |
           (bytes[offset + 1] << 8) |
           (bytes[offset + 2] << 16) |
           (bytes[offset + 3] << 24);
  }
}