import 'dart:typed_data';

class PeerAddress {
  
  final String ip;
  final int port;
  final int services;
  final int timestamp;

  PeerAddress({
    required this.ip,
    required this.port,
    required this.services,
    required this.timestamp,
  });

  Uint8List serialize() {
    final data = ByteData(30);
    var offset = 0;
    
    /// timestamp - 4 bytes
    data.setUint32(offset, timestamp, Endian.little);
    offset += 4;
    
    /// services - 8 bytes
    data.setUint64(offset, services, Endian.little);
    offset += 8;
    
    final ipParts = ip.split('.');
    if (ipParts.length == 4) {
      for (var i = 0; i < 10; i++) {
        data.setUint8(offset + i, 0);
      }
      data.setUint16(offset + 10, 0xFFFF);
      for (var i = 0; i < 4; i++) {
        data.setUint8(offset + 12 + i, int.parse(ipParts[i]));
      }
    }
    offset += 16;
    
    data.setUint16(offset, port, Endian.big);
    
    return data.buffer.asUint8List();
  }

  factory PeerAddress.deserialize(ByteData data, int offset) {
    final timestamp = data.getUint32(offset, Endian.little);
    final services = data.getUint64(offset + 4, Endian.little);
    
    bool isIPv4Mapped = true;
    for (var i = 0; i < 10; i++) {
      if (data.getUint8(offset + 12 + i) != 0) {
        isIPv4Mapped = false;
        break;
      }
    }
    
    if (data.getUint16(offset + 22, Endian.little) != 0xFFFF) {
      isIPv4Mapped = false;
    }

    String ip;
    if (isIPv4Mapped) {
      /// IPv4
      final ipBytes = List<int>.generate(4, (i) => 
        data.getUint8(offset + 24 + i));
      ip = ipBytes.join('.');
    } else {
      /// IPv6
      final ipBytes = List<int>.generate(16, (i) =>
        data.getUint8(offset + 12 + i));
      ip = _formatIPv6Address(ipBytes);
    }
    
    final port = data.getUint16(offset + 28, Endian.big);
    
    return PeerAddress(
      timestamp: timestamp,
      services: services,
      ip: ip,
      port: port,
    );
  }

  static String _formatIPv6Address(List<int> bytes) {
    assert(bytes.length == 16);
    final parts = <String>[];
    for (var i = 0; i < 16; i += 2) {
      final value = (bytes[i] << 8) | bytes[i + 1];
      parts.add(value.toRadixString(16).padLeft(4, '0'));
    }
    return parts.join(':');
  }
}