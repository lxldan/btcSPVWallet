import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/peer_adress.dart';
import 'dart:typed_data';

class AddrMessage implements Message {
  final List<PeerAddress> addresses;

  AddrMessage(this.addresses);

  @override
  MessageCommand get command => MessageCommand.addr;

  @override
  Uint8List payload() {
    final countBytes = _encodeVarInt(addresses.length);
    final addressesBytes = addresses
        .map((addr) => addr.serialize())
        .expand((bytes) => bytes)
        .toList();
    return Uint8List.fromList([
      ...countBytes,
      ...addressesBytes,
    ]);
  }

  
  factory AddrMessage.deserialize(Uint8List payload) {
    final data = ByteData.sublistView(payload);
    var offset = 0;
    
    final countResult = _decodeVarInt(payload, offset);
    final count = countResult.value;
    offset = countResult.newOffset;
    
    final addresses = <PeerAddress>[];
    for (var i = 0; i < count; i++) {
      final address = PeerAddress.deserialize(data, offset);
      addresses.add(address);
      offset += 30;
    }
    
    return AddrMessage(addresses);
  }
}

Uint8List _encodeVarInt(int value) {
  if (value < 0xFD) {
    return Uint8List.fromList([value]);
  } else if (value <= 0xFFFF) {
    final bytes = ByteData(3);
    bytes.setUint8(0, 0xFD);
    bytes.setUint16(1, value, Endian.little);
    return bytes.buffer.asUint8List();
  } else if (value <= 0xFFFFFFFF) {
    final bytes = ByteData(5);
    bytes.setUint8(0, 0xFE);
    bytes.setUint32(1, value, Endian.little);
    return bytes.buffer.asUint8List();
  } else {
    final bytes = ByteData(9);
    bytes.setUint8(0, 0xFF);
    bytes.setUint64(1, value, Endian.little);
    return bytes.buffer.asUint8List();
  }
}

class VarIntResult {
  final int value;
  final int newOffset;
  
  VarIntResult(this.value, this.newOffset);
}

VarIntResult _decodeVarInt(Uint8List data, int offset) {
  final firstByte = data[offset];
  if (firstByte < 0xFD) {
    return VarIntResult(firstByte, offset + 1);
  } else if (firstByte == 0xFD) {
    final value = ByteData.sublistView(data, offset + 1, offset + 3)
        .getUint16(0, Endian.little);
    return VarIntResult(value, offset + 3);
  } else if (firstByte == 0xFE) {
    final value = ByteData.sublistView(data, offset + 1, offset + 5)
        .getUint32(0, Endian.little);
    return VarIntResult(value, offset + 5);
  } else {
    final value = ByteData.sublistView(data, offset + 1, offset + 9)
        .getUint64(0, Endian.little);
    return VarIntResult(value, offset + 9);
  }
}