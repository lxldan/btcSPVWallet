import 'package:core/blockchain/blockchain.dart';
import 'package:core/blockchain/blockchain_sync.dart';
import 'package:core/p2p/messaging/message.dart';
import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/message_parser.dart';
import 'package:core/p2p/messaging/message_serializer.dart';
import 'package:core/p2p/messaging/messages/getheaders_message.dart';
import 'package:core/p2p/messaging/messages/headers_message.dart';
import 'package:core/p2p/messaging/messages/version_message.dart';
import 'package:core/p2p/messaging/messages/verack_message.dart';
import 'package:core/p2p/messaging/messages/ping_message.dart';
import 'package:core/p2p/messaging/messages/pong_message.dart';
import 'package:logger/logger.dart';
import 'dart:typed_data';
import 'dart:io';

enum ConnectionState {
  initial,
  connected,
  closed
}

enum ConnectionCloseReason {
  error
}

class Connection {

  ConnectionState state = ConnectionState.initial;
  bool supportsBIP158 = false;
  Socket? _socket;

  final String host;
  final int port;

  late final Stopwatch syncTimer;

  static const int _protocolVersion = 60001;

  late final logger = Logger();
  late final MessageParser _parser = MessageParser();
  late final BlockchainSync blockchainSync;

  Connection({required this.host, required this.port});

  start() async {

    blockchainSync = BlockchainSync(
      lastBlock: await Blockchain.lastBlock()
    );

    syncTimer = Stopwatch()..start();

    try {
      final versionMessage = VersionMessage(
        protocolVersion: _protocolVersion,
        services: 0,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        userAgent: '/spv_wallet:0.1/',
        lastBlock: 0,
        nonce: DateTime.now().microsecondsSinceEpoch
      );
 
      _socket = await Socket.connect(host, port);
      _socket?.add(
        MessageSerializer.serializeMessage(versionMessage)
      );

      _socket?.listen((Uint8List data) {
        _processSocketData(data);
      }, onError: (error) {
        close();
      }, onDone: () {
        logger.i('Closed by peer $host:$port');
        state = ConnectionState.closed;
      });
    } catch (error, stackTrace) {
      logger.e(
        error.toString(),
        error: error.toString(),
        stackTrace: stackTrace
      );
    }
  }

  Future close() async {
    await _socket?.close();
    _socket = null;
    state = ConnectionState.closed;
    return;
  }

  _processSocketData(Uint8List data) {
    _parser.processData(data);
    final messages = _parser.takeMessages();
    for (var message in messages) {
      _handleIncomingMessage(message);
    }
  }



  _handleIncomingMessage(Message message) async {
    try {
      switch (message.command) {
        case MessageCommand.version:
          final versionMsg = message as VersionMessage;
          if (versionMsg.protocolVersion < _protocolVersion) {
            await close();
            return;
          }
          _socket?.add(
            MessageSerializer.serializeMessage(VerackMessage())
          );
      
        case MessageCommand.verack:
          state = ConnectionState.connected;
          _sendTestGetHeadersMessage();

        case MessageCommand.ping:
          final pingMsg = message as PingMessage;
          final pongMsg = PongMessage(nonce: pingMsg.nonce);
          _socket?.add(MessageSerializer.serializeMessage(pongMsg));

        case MessageCommand.pong:
          final pongMsg = message as PongMessage;
          logger.i('Received pong message with nonce: ${pongMsg.nonce}');

        case MessageCommand.headers:
          final headers = message as HeadersMessage;
          if (headers.headers.isEmpty) {
            await blockchainSync.writeBufferToDB();
            syncTimer.stop();
            logger.i(
              'Sync completed in ${syncTimer.elapsedMilliseconds / 1000}s'
            );
            syncTimer.stop();
            return;
          }
          for (final header in headers.headers) {
            try {
              await blockchainSync.newBlock(header);
            } catch (e) {
              continue;
            }
          }
          _sendTestGetHeadersMessage();

        default:
          logger.i('Received message: $message');
      }
    } catch (e, stackTrace) {
      logger.e(
        e.toString(),
        error: e.toString(),
        stackTrace: stackTrace
      );
    }
  }

  _sendTestGetHeadersMessage() async {
    final message = GetHeadersMessage(
      version: _protocolVersion,
      hashStop: Uint8List(32),
      blockLocatorHashes: [
        blockchainSync.lastBlock.header.blockHash()
      ]
    );
    _socket?.add(
      MessageSerializer.serializeMessage(message)
    );
  }
}