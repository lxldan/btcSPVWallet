import 'dart:typed_data';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';

/*
The “getheaders” message requests a “headers” message that provides block headers starting from a particular point in the block chain. It allows a peer which has been disconnected or started for the first time to get the headers it hasn’t seen yet.

The “getheaders” message is nearly identical to the “getblocks” message, with one minor difference: the inv reply to the “getblocks” message will include no more than 500 block header hashes; the headers reply to the “getheaders” message will include as many as 2,000 block headers.

Structure of the message:
  Version:                4 bytes
  Block Locator Hashes:   variable integer (var_int) + list of 32-byte hashes
  Hash Stop:              32 bytes
*/
class GetHeadersMessage implements Message {
  final int version; // Версия протокола (4 байта)
  final List<Uint8List> blockLocatorHashes; // Список хэшей для локализации (var_int + 32 байта на хэш)
  final Uint8List hashStop; // Хэш блока, до которого нужно вернуть заголовки (32 байта)

  GetHeadersMessage({
    required this.version,
    required this.blockLocatorHashes,
    required this.hashStop,
  });

  /// Creates a GetHeadersMessage by deserializing a payload
  factory GetHeadersMessage.deserialize(Uint8List payload) {
    final data = ByteData.sublistView(payload);
    var offset = 0;

    // Read version (4 bytes)
    final version = data.getUint32(offset, Endian.little);
    offset += 4;

    // Read number of hashes (variable length var_int)
    int count;
    if (payload[offset] < 0xfd) {
      count = payload[offset];
      offset += 1;
    } else if (payload[offset] == 0xfd) {
      count = data.getUint16(offset + 1, Endian.little);
      offset += 3;
    } else if (payload[offset] == 0xfe) {
      count = data.getUint32(offset + 1, Endian.little);
      offset += 5;
    } else {
      // 0xff prefix - theoretically could be used but unlikely in practical applications
      count = data.getUint64(offset + 1, Endian.little);
      offset += 9;
    }

    // Read block locator hashes (each 32 bytes)
    final blockLocatorHashes = <Uint8List>[];
    for (var i = 0; i < count; i++) {
      final hash = Uint8List.fromList(payload.sublist(offset, offset + 32)); // Без .reversed
      blockLocatorHashes.add(hash);
      offset += 32;
    }

    // Read hash stop (32 bytes)
    final hashStop = Uint8List.fromList(payload.sublist(offset, offset + 32)); // Без .reversed

    return GetHeadersMessage(
      version: version,
      blockLocatorHashes: blockLocatorHashes,
      hashStop: hashStop,
    );
  }

  @override
  MessageCommand get command => MessageCommand.getheaders;

  @override
  Uint8List payload() {
    // Выделяем буфер с запасом для максимального размера var_int (9 байт)
    final buffer = ByteData(4 + 9 + (32 * blockLocatorHashes.length) + 32);
    var offset = 0;

    // Write version (4 bytes)
    buffer.setUint32(offset, version, Endian.little);
    offset += 4;

    // Write number of hashes (var_int)
    final count = blockLocatorHashes.length;
    if (count < 0xfd) {
      buffer.setUint8(offset, count);
      offset += 1;
    } else if (count <= 0xffff) {
      buffer.setUint8(offset, 0xfd);
      buffer.setUint16(offset + 1, count, Endian.little);
      offset += 3;
    } else if (count <= 0xffffffff) {
      buffer.setUint8(offset, 0xfe);
      buffer.setUint32(offset + 1, count, Endian.little);
      offset += 5;
    } else {
      buffer.setUint8(offset, 0xff);
      buffer.setUint64(offset + 1, count, Endian.little);
      offset += 9;
    }

    // Write block locator hashes (each 32 bytes)
    for (var hash in blockLocatorHashes) {
      buffer.buffer.asUint8List(offset, 32).setAll(0, hash); // Без .reversed
      offset += 32;
    }

    // Write hash stop (32 bytes)
    buffer.buffer.asUint8List(offset, 32).setAll(0, hashStop); // Без .reversed
    offset += 32;

    // Возвращаем только использованную часть буфера
    return buffer.buffer.asUint8List(0, offset);
  }
}