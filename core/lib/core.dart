library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:core/p2p/peers_manager.dart';
import 'package:crypto/crypto.dart';

start() async {
  await PeersManager().start();  
}

abstract class BitcoinMessage {
  // Network magic bytes (mainnet: 0xf9beb4d9)
  static final Uint8List MAINNET_MAGIC = Uint8List.fromList([0xf9, 0xbe, 0xb4, 0xd9]);
  
  // Get the command name for this message type
  String get command;
  
  // Serialize the message payload
  Uint8List serializePayload();
  
  // Calculate checksum (first 4 bytes of double SHA-256 of payload)
  Uint8List calculateChecksum(Uint8List payload) {
    var hash1 = sha256.convert(payload);
    var hash2 = sha256.convert(hash1.bytes);
    return Uint8List.fromList(hash2.bytes.sublist(0, 4));
  }
  
  // Serialize the complete message (header + payload)
  Uint8List serialize({Uint8List? magic}) {
    // Use provided magic or default to mainnet
    final networkMagic = magic ?? MAINNET_MAGIC;
    
    // Serialize the payload
    final payload = serializePayload();
    
    // Calculate the checksum
    final checksum = calculateChecksum(payload);
    
    // Prepare command bytes (12 bytes, padded with nulls)
    final commandBytes = Uint8List(12);
    final commandAscii = ascii.encode(command);
    commandBytes.setRange(0, commandAscii.length, commandAscii);
    
    // Create the full message buffer
    final messageBuffer = BytesBuilder();
    messageBuffer.add(networkMagic);
    messageBuffer.add(commandBytes);
    
    // Add payload length (4 bytes, little-endian)
    final lengthBytes = Uint8List(4);
    ByteData.view(lengthBytes.buffer).setUint32(0, payload.length, Endian.little);
    messageBuffer.add(lengthBytes);
    
    // Add checksum and payload
    messageBuffer.add(checksum);
    messageBuffer.add(payload);
    
    return messageBuffer.toBytes();
  }
}