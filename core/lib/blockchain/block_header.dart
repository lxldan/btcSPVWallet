import 'package:crypto/crypto.dart';
import 'dart:typed_data';

class BlockHeader {

  final int version;
  final Uint8List prevBlock;
  final Uint8List merkleRoot;
  final int timestamp;
  final int bits;
  final int nonce;

  BlockHeader({
    required this.version,
    required this.prevBlock,
    required this.merkleRoot,
    required this.timestamp,
    required this.bits,
    required this.nonce,
  });

  factory BlockHeader.deserialize(ByteData data, int offset) {
    if (data.lengthInBytes - offset < 80) {
      throw Exception('Invalid header length');
    }
    return BlockHeader(
      version: data.getInt32(offset, Endian.little),
      prevBlock: data.buffer.asUint8List(offset + 4, 32),
      merkleRoot: data.buffer.asUint8List(offset + 36, 32),
      timestamp: data.getUint32(offset + 68, Endian.little),
      bits: data.getUint32(offset + 72, Endian.little),
      nonce: data.getUint32(offset + 76, Endian.little),
    );
  }

  Uint8List serialize() {
    final buffer = ByteData(80);
    buffer.setInt32(0, version, Endian.little);
    buffer.buffer.asUint8List(4, 32).setAll(0, prevBlock);
    buffer.buffer.asUint8List(36, 32).setAll(0, merkleRoot);
    buffer.setUint32(68, timestamp, Endian.little);
    buffer.setUint32(72, bits, Endian.little);
    buffer.setUint32(76, nonce, Endian.little);
    return buffer.buffer.asUint8List();
  }

  String toHex(Uint8List bytes) {
    return bytes.reversed.map((b) => b.toRadixString(16).padLeft(
      2, 
      '0'
    )).join();
  }

  static Uint8List fromHex(String hex) {
    final length = hex.length ~/ 2;
    final result = Uint8List(length);
    for (int i = 0; i < length; i++) {
      result[length - 1 - i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  Uint8List computeBlockHashBytes() {
    final headerData = serialize();
    final firstHash = sha256.convert(headerData);
    final secondHash = sha256.convert(firstHash.bytes);
    return Uint8List.fromList(secondHash.bytes);
  }

  String computeBlockHash() {
    return toHex(computeBlockHashBytes());
  }

  Map<String, dynamic> toMap(int height, Uint8List chainwork) {
    final blockHash = computeBlockHash();
    return {
      'block_hash': blockHash,
      'version': version,
      'prev_block_hash': toHex(prevBlock),
      'merkle_root': toHex(merkleRoot),
      'timestamp': timestamp,
      'bits': bits,
      'nonce': nonce,
      'height': height,
      'chainwork': toHex(chainwork),
    };
  }
}