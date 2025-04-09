import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  // This line enables taking screenshots on test failures and other features
  await integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      // Save screenshots or other data after test run
      if (data != null) {
        print('Test completed with data: $data');
      }
    },
  );
} 