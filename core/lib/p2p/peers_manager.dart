import 'package:core/p2p/connection.dart';
import 'package:logger/logger.dart';

class PeersManager {
  
  final List<Connection> _activeConnections = [];
  static const int maxConnections = 1;
  late final log = Logger();
  
  start() async {
    await _connect('localhost', 8333);
  }

  Future _connect(String host, int port) async {
    if (_activeConnections.length >= maxConnections) return;
    final connection = Connection(host: host, port: port);
    try {
      await connection.start();
      _activeConnections.add(connection);
    } catch (e) {
      _activeConnections.remove(connection);
      log.e('Failed to connect to $host:$port');
    }
  }
}