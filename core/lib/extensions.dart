import 'dart:typed_data';

import 'package:crypto/crypto.dart';

String toHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(
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

/// Преобразует [Uint8List] в шестнадцатеричную строку.
/// 
/// [bytes] - входной массив байтов для преобразования
/// [upperCase] - если true, возвращает HEX в верхнем регистре (по умолчанию false)
/// [prefix] - если true, добавляет префикс "0x" (по умолчанию false)
/// [separator] - опциональный разделитель между байтами (по умолчанию пустая строка)
String uint8ListToHex(
  Uint8List bytes, {
  bool upperCase = false, 
  bool prefix = false,
  String separator = '',
}) {
  final StringBuffer buffer = StringBuffer();
  
  if (prefix) {
    buffer.write('0x');
  }
  
  for (int i = 0; i < bytes.length; i++) {
    // Преобразуем байт в hex строку и добавляем ведущий ноль при необходимости
    String byteHex = bytes[i].toRadixString(16).padLeft(2, '0');
    
    if (upperCase) {
      byteHex = byteHex.toUpperCase();
    }
    
    buffer.write(byteHex);
    
    // Добавляем разделитель между байтами, но не после последнего
    if (separator.isNotEmpty && i < bytes.length - 1) {
      buffer.write(separator);
    }
  }
  
  return buffer.toString();
}

/// Calculates the checksum for a payload.
/// 
/// The checksum is the first 4 bytes of a double SHA256 hash.
Uint8List calculateChecksum(Uint8List payload) {
  final hash1 = sha256.convert(payload).bytes;
  final hash2 = sha256.convert(hash1).bytes;
  return Uint8List.fromList(hash2.sublist(0, 4));
}