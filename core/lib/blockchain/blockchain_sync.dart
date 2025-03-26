import 'package:collection/collection.dart';
import 'package:core/blockchain/block.dart';
import 'package:core/blockchain/block_header.dart';
import 'package:core/blockchain/blockchain_db.dart';
import 'package:core/blockchain/mapper.dart';

class BlockchainSync {

  static const listEqualityChecker = ListEquality<int>();

  Block lastBlock;

  List<Block> buffer = [];

  BlockchainSync({
    required this.lastBlock
  });

  newBlock(BlockHeader header) async {
    if (buffer.length == 50000) await writeBufferToDB();
    final previousHash = lastBlock.header.blockHash();
    if (!listEqualityChecker.equals(previousHash, header.prevBlock)) {
      throw Exception(
        'BlockchainSync Error: previous block hash does not match'
      );
    }
    final newBlock = Block(
      header: header, 
      height: lastBlock.height + 1
    );
    buffer.add(newBlock);
    lastBlock = newBlock;
  }

  Future writeBufferToDB() async {
    final maps = buffer.map((block) => Mapper.blockToMap(block)).toList();
    buffer.clear();
    BlockchainDB.insertBlocks(maps);
  }
}