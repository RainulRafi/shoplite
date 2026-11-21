import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/config/app_config.dart';
import 'package:shoplite/core/network/api_client.dart';

void main() {
  test('without any dart-define the app still has a real https address', () {
    expect(AppConfig.baseUrl, startsWith('https://'));
  });

  test(
    'the dio the app builds takes its address and timeouts from AppConfig',
    () {
      final dio = createDio();

      expect(dio.options.baseUrl, AppConfig.baseUrl);
      expect(Uri.parse(dio.options.baseUrl).host, isNotEmpty);
      expect(dio.options.connectTimeout, AppConfig.connectTimeout);
      expect(dio.options.receiveTimeout, AppConfig.receiveTimeout);
    },
  );

  test('access tokens last a sensible number of minutes by default', () {
    expect(AppConfig.accessTokenMinutes, greaterThan(0));
  });
}
