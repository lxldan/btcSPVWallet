import 'package:logger/logger.dart';
import 'dart:io';

class DnsSeed {

  static final initialSeeds =  [
    "seed.bitcoin.sipa.be",
    "dnsseed.bluematt.me",
    "dnsseed.bitcoin.dashjr.org",
    "seed.bitcoinstats.com",
    "seed.bitcoin.jonasschnelli.ch",
    "seed.btc.petertodd.org",
    "seed.bitcoin.sprovoost.nl"
  ];

  static Future<List<String>> initialNodesIPs() async {
    final results = <MapEntry<String, int>>[];
    await Future.wait(initialSeeds.map((seed) async {
      try {
        final addresses = await InternetAddress.lookup(seed, type: InternetAddressType.IPv4);
        await Future.wait(addresses.map((address) async {
          final pingTime = await _measurePing(address.address);
          if (pingTime != null) {
            results.add(MapEntry(address.address, pingTime));
          }
        }));
      } catch (e) {
        Logger().e('Failed to resolve $seed');
      }
    }));

    results.sort((a, b) => a.value.compareTo(b.value));
    final bestNodes = results.toList();
    return bestNodes.map((entry) => entry.key).toList();
  }

  static Future<int?> _measurePing(String ip) async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(
        ip, 
        8333, 
        timeout: Duration(seconds: 1)
      );
      stopwatch.stop();
      socket.destroy();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      return null;
    }
  }
}