import 'package:core/blockchain/block_header.dart';
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

  static const int _protocolVersion = 60001;

  late final logger = Logger();
  late final MessageParser _parser = MessageParser();

  Connection({required this.host, required this.port});

  start() async {
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
          logger.i('Received ${headers.headers.length} headers');
          logger.i('First header: ${headers.headers.first.toString()}');

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

  _sendTestGetHeadersMessage() {
    Future.delayed(const Duration(seconds: 1), () {
      final genesisBlockHeader = BlockHeader(
        version: 1,
        prevBlock: Uint8List(32),
        merkleRoot: BlockHeader.fromHex(
          '4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b'
        ),
        timestamp: 1231006505,
        bits: 486604799,
        nonce: 2083236893,
      );

      final message = GetHeadersMessage(
        version: _protocolVersion,
        blockLocatorHashes: [
          genesisBlockHeader.computeBlockHashBytes()
        ],
        hashStop: Uint8List(32)
      );

      _socket?.add(
        MessageSerializer.serializeMessage(message)
      );
    });
  }
}