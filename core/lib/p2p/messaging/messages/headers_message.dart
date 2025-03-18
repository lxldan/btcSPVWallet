import 'dart:typed_data';
import 'package:core/blockchain/block_header.dart';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';

class HeadersMessage implements Message {
  final List<BlockHeader> headers;

  HeadersMessage(this.headers);

  @override
  MessageCommand get command => MessageCommand.headers;

  @override
  Uint8List payload() {
    final headersCount = headers.length;
    final countSize = headersCount < 0xfd ? 1 : headersCount <= 0xffff ? 3 : 5;
    final buffer = ByteData(countSize + headers.length * 81);
    var offset = 0;

    if (headersCount < 0xfd) {
      buffer.setUint8(offset, headersCount);
      offset += 1;
    } else if (headersCount <= 0xffff) {
      buffer.setUint8(offset, 0xfd);
      buffer.setUint16(offset + 1, headersCount, Endian.little);
      offset += 3;
    } else {
      buffer.setUint8(offset, 0xfe);
      buffer.setUint32(offset + 1, headersCount, Endian.little);
      offset += 5;
    }

    for (final header in headers) {
      buffer.buffer.asUint8List(offset, 80).setAll(0, header.serialize());
      offset += 80;
      buffer.setUint8(offset, 0);
      offset += 1;
    }

    return buffer.buffer.asUint8List(0, offset);
  }

  factory HeadersMessage.deserialize(Uint8List payload) {
    final data = ByteData.sublistView(payload);
    var offset = 0;

    var count = 0;
    if (payload[0] < 0xfd) {
      count = payload[0];
      offset = 1;
    } else if (payload[0] == 0xfd) {
      count = data.getUint16(1, Endian.little);
      offset = 3;
    } else if (payload[0] == 0xfe) {
      count = data.getUint32(1, Endian.little);
      offset = 5;
    }

    final headers = <BlockHeader>[];
    for (var i = 0; i < count; i++) {
      headers.add(BlockHeader.deserialize(data, offset));
      offset += 80;
      offset += 1;
    }

    return HeadersMessage(headers);
  }
}