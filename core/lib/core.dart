library;

import 'package:core/blockchain/block_header.dart';
import 'package:core/blockchain/chainwork_calculator.dart';
import 'package:core/p2p/peers_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:typed_data';

start() async {

  var databasesPath = await getDatabasesPath();
  print(databasesPath);

  Database database = await openDatabase(
    'headers.db', 
    version: 1,
    onCreate: (Database db, int version) async {
      await db.execute('''
        CREATE TABLE block_headers (
          block_hash TEXT PRIMARY KEY,
          version INTEGER,
          prev_block_hash TEXT,
          merkle_root TEXT,
          timestamp INTEGER,
          bits INTEGER,
          nonce INTEGER,
          height INTEGER,
          chainwork TEXT
        )
      ''');
  });

  await _insertGenesisBlock(database);

  await PeersManager().start();  
}

Future _insertGenesisBlock(Database db) async {
  final genesisBlock = BlockHeader(
    version: 1,
    prevBlock: Uint8List(32),
    merkleRoot: BlockHeader.fromHex(
      '4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b'
    ),
    timestamp: 1231006505,
    bits: 486604799,
    nonce: 2083236893,
  );

  final blockHash = genesisBlock.computeBlockHash();
  print('Computed Genesis Block Hash: $blockHash');
 
  final chainWork = ChainworkCalculator().computeChainwork(
    genesisBlock, 
    Uint8List(32)
  );

  await db.insert(
    'block_headers',
    genesisBlock.toMap(0, chainWork),
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
  print('Genesis block inserted successfully');
}