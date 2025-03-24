import 'package:core/blockchain/block.dart';
import 'package:core/blockchain/blockchain_db.dart';
import 'package:core/blockchain/mapper.dart';

class Blockchain {


  static Future<Block> lastBlock() async {
    final lastBlockMap = await BlockchainDB.lastBlock();
    final block = Mapper.blockFromMap(lastBlockMap);
    return block;
  }
}