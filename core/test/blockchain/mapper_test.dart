import 'package:core/extensions.dart';
import 'package:test/test.dart';
import 'package:core/blockchain/mapper.dart';
import 'package:core/blockchain/block.dart';
import 'package:core/blockchain/block_header.dart';

void main() {
  group('Mapper', () {
    final testHeader = BlockHeader(
      version: 1,
      prevBlock: fromHex("000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"),
      merkleRoot: fromHex("4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b"),
      timestamp: 1231006505,
      bits: 486604799,
      nonce: 2083236893
    );

    final testBlock = Block(
      header: testHeader,
      height: 0
    );

    test('blockHeaderToMap converts BlockHeader to Map correctly', () {
      final map = Mapper.blockHeaderToMap(testHeader);
      
      expect(map[MapperKey.version], equals(testHeader.version));
      expect(map[MapperKey.prevBlockHash], equals(testHeader.prevBlock));
      expect(map[MapperKey.merkleRoot], equals(testHeader.merkleRoot));
      expect(map[MapperKey.timestamp], equals(testHeader.timestamp));
      expect(map[MapperKey.bits], equals(testHeader.bits));
      expect(map[MapperKey.nonce], equals(testHeader.nonce));
    });

    test('headerFromMap converts Map to BlockHeader correctly', () {
      final map = Mapper.blockHeaderToMap(testHeader);
      final header = Mapper.headerFromMap(map);

      expect(header.version, equals(testHeader.version));
      expect(header.prevBlock, equals(testHeader.prevBlock));
      expect(header.merkleRoot, equals(testHeader.merkleRoot));
      expect(header.timestamp, equals(testHeader.timestamp));
      expect(header.bits, equals(testHeader.bits));
      expect(header.nonce, equals(testHeader.nonce));
    });

    test('blockToMap converts Block to Map correctly', () {
      final map = Mapper.blockToMap(testBlock);

      expect(map[MapperKey.height], equals(testBlock.height));
      expect(map[MapperKey.version], equals(testBlock.header.version));
      expect(map[MapperKey.prevBlockHash], equals(testBlock.header.prevBlock));
      expect(map[MapperKey.merkleRoot], equals(testBlock.header.merkleRoot));
      expect(map[MapperKey.timestamp], equals(testBlock.header.timestamp));
      expect(map[MapperKey.bits], equals(testBlock.header.bits));
      expect(map[MapperKey.nonce], equals(testBlock.header.nonce));
    });

    test('blockFromMap converts Map to Block correctly', () {
      final map = Mapper.blockToMap(testBlock);
      final block = Mapper.blockFromMap(map);

      expect(block.height, equals(testBlock.height));
      expect(block.header.version, equals(testBlock.header.version));
      expect(block.header.prevBlock, equals(testBlock.header.prevBlock));
      expect(block.header.merkleRoot, equals(testBlock.header.merkleRoot));
      expect(block.header.timestamp, equals(testBlock.header.timestamp));
      expect(block.header.bits, equals(testBlock.header.bits));
      expect(block.header.nonce, equals(testBlock.header.nonce));
    });
  });
}
