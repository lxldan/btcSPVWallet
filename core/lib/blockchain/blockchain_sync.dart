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
    if (buffer.length == 50000) await _writeBufferToDB();
    
    final previousHash = lastBlock.header.blockHash();
    if (!listEqualityChecker.equals(previousHash, header.prevBlock)) {
      throw Exception(
        'Invalid block: previous block hash does not match'
      );
    }

    final newHeight = lastBlock.height + 1;
    final newBlock = Block(
      header: header, 
      height: newHeight
    );

    buffer.add(newBlock);
    lastBlock = newBlock;

    print('New best height $newHeight');
  }

  Future _writeBufferToDB() async {
    final blockMaps = buffer.map(
      (block) => Mapper.blockToMap(block)
    ).toList();
    await BlockchainDB.insertBlocks(blockMaps);
    buffer.clear();
  }

}