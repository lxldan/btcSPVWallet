import 'dart:typed_data';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';

/*
The “getheaders” message requests a “headers” message that provides block headers starting from a particular point in the block chain. It allows a peer which has been disconnected or started for the first time to get the headers it hasn’t seen yet.

The “getheaders” message is nearly identical to the “getblocks” message, with one minor difference: the inv reply to the “getblocks” message will include no more than 500 block header hashes; the headers reply to the “getheaders” message will include as many as 2,000 block headers.

Structure of the message:
  Version:                4 bytes
  Block Locator Hashes:   variable integer
  Hash Stop:              32 bytes
*/
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