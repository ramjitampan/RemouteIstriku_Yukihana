import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_yuki/services/connection_validator.dart';

void main() {
  group('ConnectionValidator.ipv4', () {
    for (final ip in [
      '192.168.1.1',
      '192.168.1.9',
      '192.168.1.11',
      '192.168.1.20',
      '192.168.1.100',
      '192.168.0.25',
      '10.0.0.5',
    ]) {
      test('accepts $ip', () => expect(ConnectionValidator.ipv4(ip), isNull));
    }
    for (final ip in [
      '',
      '127.0.0',
      '256.1.1.1',
      '1.2.3.999',
      '1.a.3.4',
      '1..3.4',
      '1.2.3.4.5',
    ]) {
      test(
        'rejects "$ip"',
        () => expect(ConnectionValidator.ipv4(ip), isNotNull),
      );
    }
  });

  group('ConnectionValidator.port', () {
    test('accepts boundary values', () {
      expect(ConnectionValidator.port('1'), isNull);
      expect(ConnectionValidator.port('65535'), isNull);
      expect(ConnectionValidator.port('8123'), isNull);
    });
    for (final port in ['', '0', '65536', '-1', 'abc']) {
      test(
        'rejects "$port"',
        () => expect(ConnectionValidator.port(port), isNotNull),
      );
    }
  });
}
