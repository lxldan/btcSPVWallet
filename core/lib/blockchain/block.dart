import 'package:core/blockchain/block_header.dart';

class Block {

  final BlockHeader header;
  final int height;

  Block({
    required this.header,
    required this.height
  });
}