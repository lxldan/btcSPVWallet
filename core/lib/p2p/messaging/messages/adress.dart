import 'dart:typed_data';

/*
 Encapsulated network IP address uses in Addr message

Structure:
    Timestamp:          4 bytes - Unix time (when the address was last seen; available since protocol version 31402)
    Services:           8 bytes - Bitmask of supported services (e.g., NODE_NETWORK)
    IP Address:         16 bytes - The IP address (IPv4 addresses are represented as IPv4-mapped IPv6)
    Port:               2 bytes - The port number in network byte order (typically 8333)
*/

class Address {
  final String ip;
  final int port;
  final int services;
  final int timestamp;

  Address({
    required this.ip,
    required this.port,
    required this.services,
    required this.timestamp,
  });

  /// Serializes the PeerAddress object into a 30-byte array
  Uint8List serialize() {
    final data = ByteData(30); // Total size: 4 (timestamp) + 8 (services) + 16 (ip) + 2 (port)
    var offset = 0;

    // Write timestamp (4 bytes, little-endian)
    data.setUint32(offset, timestamp, Endian.little);
    offset += 4;

    // Write services (8 bytes, little-endian)
    data.setUint64(offset, services, Endian.little);
    offset += 8;

    // Handle IP address
    if (ip.contains(':')) {
      // IPv6 address
      final ipv6Bytes = _parseIPv6(ip);
      for (var i = 0; i < 16; i++) {
        data.setUint8(offset + i, ipv6Bytes[i]);
      }
    } else if (ip.split('.').length == 4) {
      // IPv4 address mapped to IPv6 (::ffff:a.b.c.d)
      for (var i = 0; i < 10; i++) {
        data.setUint8(offset + i, 0); // First 10 bytes are 0
      }
      data.setUint16(offset + 10, 0xFFFF, Endian.big); // IPv4-mapped prefix
      final ipParts = ip.split('.');
      for (var i = 0; i < 4; i++) {
        data.setUint8(offset + 12 + i, int.parse(ipParts[i]));
      }
    } else {
      throw FormatException('Invalid IP address: $ip');
    }
    offset += 16;

    // Write port (2 bytes, big-endian)
    data.setUint16(offset, port, Endian.big);

    return data.buffer.asUint8List();
  }

  /// Deserializes a PeerAddress from ByteData starting at the given offset
  factory Address.deserialize(ByteData data, int offset) {
    // Read timestamp (4 bytes, little-endian)
    final timestamp = data.getUint32(offset, Endian.little);
    
    // Read services (8 bytes, little-endian)
    final services = data.getUint64(offset + 4, Endian.little);

    // Check if the address is an IPv4-mapped IPv6 address
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
      // Deserialize IPv4 address
      final ipBytes = List<int>.generate(4, (i) => data.getUint8(offset + 24 + i));
      ip = ipBytes.join('.');
    } else {
      // Deserialize IPv6 address
      final ipBytes = List<int>.generate(16, (i) => data.getUint8(offset + 12 + i));
      ip = _formatIPv6Address(ipBytes);
    }

    // Read port (2 bytes, big-endian)
    final port = data.getUint16(offset + 28, Endian.big);

    return Address(
      timestamp: timestamp,
      services: services,
      ip: ip,
      port: port,
    );
  }

  /// Parses an IPv6 address string into a 16-byte array
  static Uint8List _parseIPv6(String ip) {
    final parts = ip.split(':');
    if (parts.length != 8) {
      throw FormatException('Invalid IPv6 address: $ip');
    }
    final bytes = Uint8List(16);
    for (var i = 0; i < 8; i++) {
      final value = int.parse(parts[i], radix: 16);
      bytes[i * 2] = (value >> 8) & 0xFF;
      bytes[i * 2 + 1] = value & 0xFF;
    }
    return bytes;
  }

  /// Formats a 16-byte IPv6 address into a string
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