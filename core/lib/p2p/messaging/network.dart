import 'dart:typed_data';

/// Enum representing different Bitcoin networks
enum Network {
  mainnet,
  testnet,
  regtest,
  signet;

  // Magic bytes to identify messages on each network
  Uint8List get magicBytes {
    switch (this) {
      case Network.mainnet:
        return Uint8List.fromList([0xf9, 0xbe, 0xb4, 0xd9]);
      case Network.testnet:
        return  Uint8List.fromList([0x0b, 0x11, 0x09, 0x07]);
      case Network.regtest:
        return Uint8List.fromList([0xfa, 0xbf, 0xb5, 0xda]);
      case Network.signet:
        return Uint8List.fromList([0x0a, 0x03, 0xcf, 0x40]);
    }
  }
}