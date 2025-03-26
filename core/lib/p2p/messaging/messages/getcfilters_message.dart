import 'dart:typed_data';

import 'package:core/core.dart';

class GetCFiltersMessage extends BitcoinMessage {
  final int filterType;
  final int startHeight;
  final Uint8List stopHash;
  
  GetCFiltersMessage({
    this.filterType = 0, // 0 = BASIC filter type
    required this.startHeight,
    required this.stopHash,
  }) {
    if (stopHash.length != 32) {
      throw ArgumentError('Stop hash must be 32 bytes');
    }
  }
  
  @override
  String get command => "getcfilters";
  
  @override
  Uint8List serializePayload() {
    final buffer = ByteData(37); // 1 + 4 + 32 bytes
    
    // Filter type (1 byte)
    buffer.setUint8(0, filterType);
    
    // Start height (4 bytes, little-endian)
    buffer.setUint32(1, startHeight, Endian.little);
    
    // Stop hash (32 bytes)
    for (int i = 0; i < 32; i++) {
      buffer.setUint8(5 + i, stopHash[i]);
    }
    
    return Uint8List.view(buffer.buffer);
  }
}