import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';

class BlockchainDBKeys {
  static const database = 'blockchain.db';
  static const blocks = 'blocks';
  static const height = 'height';
}

class BlockchainDB {

  static Map<String, dynamic> genesisBlock = {
    'version': '1', 
    'prev_block_hash': Uint8List(32),
    'merkle_root': Uint8List.fromList([
      59, 163, 237, 253, 122, 123, 18, 178, 122, 199, 44, 62, 103, 118, 143, 97, 127, 200, 27, 195, 136, 138, 81, 50, 58, 159, 184, 170, 75, 30, 94, 74
    ]),
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
            height INTEGER PRIMARY KEY,
            version INTEGER,
            prev_block_hash BLOB,
            merkle_root BLOB,
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