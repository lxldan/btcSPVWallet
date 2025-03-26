import 'dart:typed_data';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';

class CFilterMessage implements Message {
  final int filterType;
  final Uint8List blockHash;
  final Uint8List filterData;

  CFilterMessage({
    required this.filterType,
    required this.blockHash,
    required this.filterData,
  });

  factory CFilterMessage.deserialize(Uint8List payload) {
    final data = ByteData.sublistView(payload);
    var offset = 0;

    final filterType = data.getUint8(offset);
    offset += 1;

    final blockHash = Uint8List.fromList(payload.sublist(offset, offset + 32));
    offset += 32;

    // Читаем длину filterData (var_int)
    int length;
    if (payload[offset] < 0xfd) {
      length = payload[offset];
      offset += 1;
    } else if (payload[offset] == 0xfd) {
      length = data.getUint16(offset + 1, Endian.little);
      offset += 3;
    } else if (payload[offset] == 0xfe) {
      length = data.getUint32(offset + 1, Endian.little);
      offset += 5;
    } else {
      length = data.getUint64(offset + 1, Endian.little);
      offset += 9;
    }

    final filterData = Uint8List.fromList(payload.sublist(offset, offset + length));

    return CFilterMessage(
      filterType: filterType,
      blockHash: blockHash,
      filterData: filterData,
    );
  }

  @override
  MessageCommand get command => MessageCommand.cfilter;

  @override
  Uint8List payload() {
    // Реализация сериализации для отправки (если нужно)
    throw UnimplementedError();
  }
}