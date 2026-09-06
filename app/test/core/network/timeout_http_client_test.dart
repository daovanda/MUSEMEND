import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:musemend/core/network/timeout_http_client.dart';

void main() {
  test('fails a request that exceeds the configured timeout', () async {
    final inner = MockClient.streaming((_, _) async {
      await Completer<void>().future;
      return http.StreamedResponse(const Stream.empty(), 200);
    });
    final client = TimeoutHttpClient(
      inner,
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      client.get(Uri.https('example.invalid')),
      throwsA(isA<TimeoutException>()),
    );
    client.close();
  });
}
