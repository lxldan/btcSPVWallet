import 'package:core/blockchain/block_header.dart';
import 'dart:typed_data';

class ChainworkCalculator {
  
  BigInt _bitsToTarget(int bits) {
    final exponent = bits >> 24;
    final mantissa = bits & 0xFFFFFF;
    return BigInt.from(mantissa) << (8 * (exponent - 3));
  }

  BigInt _calculateWork(int bits) {
    final target = _bitsToTarget(bits);
    return (BigInt.one << 256) ~/ target;
  }

  Uint8List computeChainwork(
    BlockHeader block, 
    Uint8List prevChainwork
  ) {
    final prevWork = BigInt.parse(
      prevChainwork.map(
        (b) => b.toRadixString(16).padLeft(2, '0')
      ).join(),
      radix: 16
    );
    final currentWork = _calculateWork(block.bits);
    final newWork = prevWork + currentWork;
    final hex = newWork.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList(
      List.generate(32, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16))
    );
  }

  Uint8List computeGenesisChainwork(BlockHeader genesisBlock) {
    final currentWork = _calculateWork(genesisBlock.bits);
    final hex = currentWork.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList(
      List.generate(32, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)),
    );
  }

  String computeChainworkHex(
    BlockHeader block, 
    {Uint8List? prevChainwork}
  ) {
    if (prevChainwork == null) {
      return _toHexBigEndian(computeGenesisChainwork(block));
    } else {
      return _toHexBigEndian(computeChainwork(block, prevChainwork));
    }
  }

  String _toHexBigEndian(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}