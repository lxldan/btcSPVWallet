import 'dart:typed_data';

String toHex(Uint8List bytes) {
  return bytes.reversed.map((b) => b.toRadixString(16).padLeft(
    2, 
    '0'
  )).join();
}

Uint8List fromHex(String hex) {
  final length = hex.length ~/ 2;
  final result = Uint8List(length);
  for (int i = 0; i < length; i++) {
    result[length - 1 - i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}