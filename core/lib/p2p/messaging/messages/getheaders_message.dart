import 'dart:typed_data';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';

class GetHeadersMessage implements Message {
  final int version;
  final List<Uint8List> blockLocatorHashes;
  final Uint8List hashStop;

  GetHeadersMessage({
    required this.version,
    required this.blockLocatorHashes,
    required this.hashStop,
  });

  @override
  MessageCommand get command => MessageCommand.getheaders;

  @override
  Uint8List payload() {
    final buffer = ByteData(
      4 + 9 + (32 * blockLocatorHashes.length) + 32
    );
    var offset = 0;

    buffer.setUint32(offset, version, Endian.little);
    offset += 4;

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

    for (var hash in blockLocatorHashes) {
      buffer.buffer.asUint8List(offset, 32).setAll(0, hash.reversed);
      offset += 32;
    }

    buffer.buffer.asUint8List(offset, 32).setAll(0, hashStop.reversed);
    offset += 32;

    return buffer.buffer.asUint8List(0, offset);
  }
}