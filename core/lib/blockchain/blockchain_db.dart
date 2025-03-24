import 'package:sqflite/sqflite.dart';

class BlockchainDBKeys {
  static const database = 'blockchain.db';
  static const blocks = 'blocks';
  static const height = 'height';
}

class BlockchainDB {

  static const Map<String, dynamic> genesisBlock = {
    'version': '1', 
    'prev_block_hash': '0000000000000000000000000000000000000000000000000000000000000000',
    'merkle_root': '4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b',
    'timestamp': 1231006505,
    'bits': 486604799,
    'nonce': 2083236893,
    'height': 0
  };

  static Future<Map<String, dynamic>> lastBlock() async {
    final db = await database();
    final List<Map<String, dynamic>> maps = await db.query(
      BlockchainDBKeys.blocks,
      orderBy: '${BlockchainDBKeys.height} DESC',
      limit: 1
    );
    return maps.first;
  }

  static Future<Database> database() async {
    return await openDatabase(
      'blockchain.db', 
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE blocks (
            height INTEGER,
            version INTEGER,
            prev_block_hash TEXT,
            merkle_root TEXT,
            timestamp INTEGER,
            bits INTEGER,
            nonce INTEGER
          )'''
        );
        await db.insert(
          BlockchainDBKeys.blocks,
          genesisBlock
        );
      }
    );
  }

  static Future insertBlock(Map<String, dynamic> map) async {
    final db = await openDatabase(BlockchainDBKeys.database);
    await db.insert(
      BlockchainDBKeys.blocks,
      map,
      conflictAlgorithm: ConflictAlgorithm.ignore
    );
  }

  static insertBlocks(List<Map<String, dynamic>> maps) async {
    final db = await openDatabase(BlockchainDBKeys.database);
    final batch = db.batch();
    for (final map in maps) {
      batch.insert(
        BlockchainDBKeys.blocks,
        map,
        conflictAlgorithm: ConflictAlgorithm.ignore
      );
    }
    await batch.commit(noResult: true);
  }
}