import 'package:core/blockchain/block.dart';
import 'package:core/blockchain/block_header.dart';

class MapperKey {
  static const blockHash = 'block_hash';
  static const version = 'version';
  static const prevBlockHash = 'prev_block';
  static const merkleRoot = 'merkle_root';
  static const timestamp = 'timestamp';
  static const bits = 'bits';
  static const nonce = 'nonce';
  static const height = 'height';
  static const chainwork = 'chainwork';
}

class Mapper {

  static Block blockFromMap(Map<String, dynamic> map) {
    final header = headerFromMap(map);
    return Block(
      header: header,
      height: map[MapperKey.height],
    );
  }

  static BlockHeader headerFromMap(Map<String, dynamic> map) {
    return BlockHeader(
      version: map[MapperKey.version],
      prevBlock: map[MapperKey.prevBlockHash],
      merkleRoot: map[MapperKey.merkleRoot],
      timestamp: map[MapperKey.timestamp],
      bits: map[MapperKey.bits],
      nonce: map[MapperKey.nonce],
    );
  }

  static Map<String, dynamic> blockHeaderToMap(BlockHeader header) {
    return {
      MapperKey.version: header.version,
      MapperKey.prevBlockHash: header.prevBlock,
      MapperKey.merkleRoot: header.merkleRoot,
      MapperKey.timestamp: header.timestamp,
      MapperKey.bits: header.bits,
      MapperKey.nonce: header.nonce
    };
  }

  static Map<String, dynamic> blockToMap(Block block) {
    final headerMap = blockHeaderToMap(block.header);
    headerMap[MapperKey.height] = block.height;
    return headerMap;
  }
}