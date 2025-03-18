import 'package:core/p2p/messaging/message_command.dart';
import 'dart:typed_data';

abstract interface class Message {
  MessageCommand get command;
  Uint8List payload();
}