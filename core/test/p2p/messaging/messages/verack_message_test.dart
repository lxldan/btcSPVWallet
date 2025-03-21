import 'package:core/p2p/messaging/message_command.dart';
import 'package:core/p2p/messaging/messages/verack_message.dart';
import 'package:test/test.dart';

/*
The verack message is sent in reply to 'version' message. 
This message consists of only a message header with the command string "verack".
*/
void main() {
  group('VerackMessage', () {
    late VerackMessage verackMessage;

    setUp(() {
      verackMessage = VerackMessage();
    });

    test('command returns MessageCommand.verack', () {
      expect(verackMessage.command, equals(MessageCommand.verack));
    });

    test('payload returns empty Uint8List', () {
      final payload = verackMessage.payload();
      
      expect(payload.length, equals(0));
    });
  });
}
