import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;

/*
When a node creates an outgoing connection, it will immediately advertise its version. 
The remote node will respond with its version. 
No further communication is possible until both peers have exchanged their version.

Structure of the message:
  Version:                4 bytes - 31900 (version 0.3.19)
  Services:               8 bytes - 1 (NODE_NETWORK services)
  Timestamp:              8 bytes - Mon Dec 20 21:50:14 EST 2010
  Recipient Address:     26 bytes - Network Address information
  Sender Address:        26 bytes - Network Address information
  Node Unique ID:         8 bytes - Random unique ID for the node
  Sub-version String:     1 byte  - Empty string (0 bytes long)
  Last Block Index:       4 bytes - Block #98645
*/
class VersionMessage implements Message {
  
  final int protocolVersion;
  final int services;
  final int timestamp;
  final int lastBlock;
  final String userAgent;
  final int nonce;
  final bool relay;

  @override
  MessageCommand get command => MessageCommand.version;

  VersionMessage({
    required this.protocolVersion,
    required this.services,
    required this.timestamp,
    required this.userAgent,
    required this.lastBlock,
    required this.nonce,
    this.relay = true,
  });

  /// Creates a new VersionMessage with randomly 
  /// generated nonce and current timestamp
  factory VersionMessage.create({
    required int protocolVersion,
    required int services,
    required String userAgent,
    required int lastBlock,
    bool relay = true,
  }) {
    final random = math.Random();
    // Generate a random 64-bit nonce
    final nonce = random.nextInt(0x7FFFFFFF) * 2 + random.nextInt(2);
    
    // Current timestamp in seconds since epoch
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    return VersionMessage(
      protocolVersion: protocolVersion,
      services: services,
      timestamp: timestamp,
      userAgent: userAgent,
      lastBlock: lastBlock,
      nonce: nonce,
      relay: relay,
    );
  }

  @override
  Uint8List payload() {
    final userAgentBytes = utf8.encode(userAgent);
    // Calculate complete message size
    // 4 (version) + 8 (services) + 8 (timestamp) + 26 (addr_recv) + 26 (addr_from) + 8 (nonce) + 
    // 1 (user agent length) + userAgentBytes.length + 4 (lastBlock) + 1 (relay)
    final payloadSize = 86 + userAgentBytes.length;
    final payload = ByteData(payloadSize);
    
    int offset = 0;
    
    // Version - 4 bytes
    payload.setInt32(offset, protocolVersion, Endian.little);
    offset += 4;
    
    // Services - 8 bytes
    payload.setUint64(offset, services, Endian.little);
    offset += 8;
    
    // Timestamp - 8 bytes
    payload.setInt64(offset, timestamp, Endian.little);
    offset += 8;
    
    // addr_recv - 26 bytes (services[8] + ip[16] + port[2])
    payload.setUint64(offset, services, Endian.little); // services
    offset += 8;
    // IP address - 16 bytes (IPv6)
    for (int i = 0; i < 16; i++) {
      payload.setUint8(offset + i, 0); // Zero-filled for now
    }
    offset += 16;
    payload.setUint16(offset, 8333, Endian.little); // default Bitcoin port
    offset += 2;
    
    // addr_from - 26 bytes (services[8] + ip[16] + port[2])
    payload.setUint64(offset, services, Endian.little); // services
    offset += 8;
    // IP address - 16 bytes (IPv6)
    for (int i = 0; i < 16; i++) {
      payload.setUint8(offset + i, 0); // Zero-filled for now
    }
    offset += 16;
    payload.setUint16(offset, 8333, Endian.little); // default Bitcoin port
    offset += 2;
    
    // Nonce - 8 bytes
    payload.setUint64(offset, nonce, Endian.little);
    offset += 8;
    
    // User agent - variable length
    payload.setUint8(offset, userAgentBytes.length); // User agent length
    offset += 1;
    
    for (int i = 0; i < userAgentBytes.length; i++) {
      payload.setUint8(offset + i, userAgentBytes[i]);
    }
    offset += userAgentBytes.length;
    
    // Last block - 4 bytes
    payload.setInt32(offset, lastBlock, Endian.little);
    offset += 4;
    
    // Relay - 1 byte
    payload.setUint8(offset, relay ? 1 : 0);
    
    return payload.buffer.asUint8List();
  }

  factory VersionMessage.deserialize(Uint8List payload) {
    final data = ByteData.sublistView(payload);
    int offset = 0;
    
    // Version - 4 bytes
    final protocolVersion = data.getInt32(offset, Endian.little);
    offset += 4;
    
    // Services - 8 bytes
    final services = data.getUint64(offset, Endian.little);
    offset += 8;
    
    // Timestamp - 8 bytes
    final timestamp = data.getInt64(offset, Endian.little);
    offset += 8;
    
    // Skip addr_recv - 26 bytes
    offset += 26;
    
    // Skip addr_from - 26 bytes
    offset += 26;
    
    // Nonce - 8 bytes
    final nonce = data.getUint64(offset, Endian.little);
    offset += 8;
    
    // User agent - variable length
    final userAgentLength = data.getUint8(offset);
    offset += 1;
    
    final userAgentBytes = payload.sublist(offset, offset + userAgentLength);
    final userAgent = utf8.decode(userAgentBytes);
    offset += userAgentLength;
    
    // Last block - 4 bytes
    final lastBlock = data.getInt32(offset, Endian.little);
    offset += 4;
    
    // Relay - 1 byte (if available in the payload)
    bool relay = true; // Default to true per BIP37
    if (offset < payload.length) {
      relay = data.getUint8(offset) == 1;
    }
    
    return VersionMessage(
      protocolVersion: protocolVersion,
      services: services,
      timestamp: timestamp,
      userAgent: userAgent,
      lastBlock: lastBlock,
      nonce: nonce,
      relay: relay,
    );
  }

  @override
  String toString() {
    return '''
      VersionMessage {
        protocolVersion: $protocolVersion, '
        'services: $services,'
        'timestamp: $timestamp,'
        'userAgent: $userAgent,'
        'lastBlock: $lastBlock,'
        'nonce: $nonce,'
        'relay: $relay
      }
    ''';
  }
}