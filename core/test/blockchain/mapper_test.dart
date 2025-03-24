import 'package:test/test.dart';
import 'package:core/blockchain/mapper.dart';
import 'package:core/blockchain/block.dart';
import 'package:core/blockchain/block_header.dart';
import 'package:core/extensions.dart';

void main() {
  group('Mapper', () {
    final testHeaderMap = {
      MapperKey.blockHash: 'ab12cd34ef56',
      MapperKey.version: 1,
      MapperKey.prevBlockHash: '0000000000000000000000000000000000000000000000000000000000000000',
      MapperKey.merkleRoot: '4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b',
      MapperKey.timestamp: 1231006505,
      MapperKey.bits: 486604799,
      MapperKey.nonce: 2083236893,
    };
    
    final testBlockMap = Map<String, dynamic>.from(testHeaderMap)
      ..[MapperKey.height] = 0;
    
    test('headerFromMap creates correct BlockHeader', () {
      final header = Mapper.headerFromMap(testHeaderMap);
      
      expect(header.version, equals(1));
      expect(toHex(header.prevBlock), equals('0000000000000000000000000000000000000000000000000000000000000000'));
      expect(toHex(header.merkleRoot), equals('4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b'));
      expect(header.timestamp, equals(1231006505));
      expect(header.bits, equals(486604799));
      expect(header.nonce, equals(2083236893));
    });
    
    test('blockHeaderToMap creates correct map', () {
      final header = BlockHeader(
        version: 1,
        prevBlock: fromHex('0000000000000000000000000000000000000000000000000000000000000000'),
        merkleRoot: fromHex('4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b'),
        timestamp: 1231006505,
        bits: 486604799,
        nonce: 2083236893
      );
      
      final map = Mapper.blockHeaderToMap(header);
      
      expect(map[MapperKey.version], equals(1));
      expect(map[MapperKey.prevBlockHash], equals('0000000000000000000000000000000000000000000000000000000000000000'));
      expect(map[MapperKey.merkleRoot], equals('4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b'));
      expect(map[MapperKey.timestamp], equals(1231006505));
      expect(map[MapperKey.bits], equals(486604799));
      expect(map[MapperKey.nonce], equals(2083236893));
    });
    
    test('blockFromMap creates correct Block', () {
      final block = Mapper.blockFromMap(testBlockMap);
      
      expect(block.height, equals(0));
      expect(block.header.version, equals(1));
    });
    
    test('blockToMap creates correct map', () {
      final header = BlockHeader(
        version: 1,
        prevBlock: fromHex('0000000000000000000000000000000000000000000000000000000000000000'),
        merkleRoot: fromHex('4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b'),
        timestamp: 1231006505,
        bits: 486604799,
        nonce: 2083236893
      );
      
      final block = Block(
        header: header,
        height: 0
      );
      
      final map = Mapper.blockToMap(block);
      
      expect(map[MapperKey.blockHash], isNotNull);
      expect(map[MapperKey.height], equals(0));
    });
  });
}