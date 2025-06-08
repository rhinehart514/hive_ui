import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/data/datasources/remote_config_source.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the generated mocks file
import 'remote_config_source_test.mocks.dart';

@GenerateMocks([FirebaseRemoteConfig])
void main() {
  late MockFirebaseRemoteConfig mockRemoteConfig;
  late FirebaseRemoteConfigSource dataSource;

  // Define expected default values from the source file for comparison
  const List<String> defaultInterests = [
    'Art', 'Business', 'Computer Science', 'Engineering', 'Health',
    'Literature', 'Mathematics', 'Music', 'Photography', 'Physics',
    'Sports', 'Theatre',
  ];
  const List<String> defaultAllowedDomains = ['buffalo.edu'];

  setUp(() {
    // Create mock instance
    mockRemoteConfig = MockFirebaseRemoteConfig();
    // Create the data source with the mock
    dataSource = FirebaseRemoteConfigSource(mockRemoteConfig);

    // Default stubbing for fetch/activate/defaults in initialize
    // Adjust these in specific tests if needed
    when(mockRemoteConfig.setConfigSettings(any)).thenAnswer((_) async => {});
    when(mockRemoteConfig.setDefaults(any)).thenAnswer((_) async => {});
    when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
  });

  group('FirebaseRemoteConfigSource Tests', () {
    group('initialize', () {
      test('should call setConfigSettings, setDefaults, and fetchAndActivate', () async {
        await dataSource.initialize();

        verify(mockRemoteConfig.setConfigSettings(any)).called(1);
        // Verify defaults contain expected keys
        verify(mockRemoteConfig.setDefaults(argThat(allOf(
          containsPair('interests_list', json.encode(defaultInterests)),
          containsPair('allowed_domains', json.encode(defaultAllowedDomains)),
          containsPair('auth_v1_enabled', true),
        )))).called(1);
        verify(mockRemoteConfig.fetchAndActivate()).called(1);
      });

      test('should handle exceptions during initialization gracefully', () async {
        when(mockRemoteConfig.fetchAndActivate()).thenThrow(Exception('Fetch failed'));
        
        // Expect no exception to be thrown from initialize itself
        await expectLater(dataSource.initialize(), completes);
        // Verify methods were still called
        verify(mockRemoteConfig.setConfigSettings(any)).called(1);
        verify(mockRemoteConfig.setDefaults(any)).called(1);
        verify(mockRemoteConfig.fetchAndActivate()).called(1);
      });
    });

    group('getInterestsList', () {
      test('should return decoded list when Remote Config provides valid JSON', () async {
        final interests = ['Tech', 'Gaming', 'Music'];
        when(mockRemoteConfig.getString('interests_list')).thenReturn(json.encode(interests));

        final result = await dataSource.getInterestsList();

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(interests));
        verify(mockRemoteConfig.getString('interests_list')).called(1);
      });

      test('should return default list when Remote Config returns empty string', () async {
        when(mockRemoteConfig.getString('interests_list')).thenReturn('');

        final result = await dataSource.getInterestsList();

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(defaultInterests));
        verify(mockRemoteConfig.getString('interests_list')).called(1);
      });

      test('should return default list when Remote Config throws error', () async {
        when(mockRemoteConfig.getString('interests_list')).thenThrow(Exception('Config error'));

        final result = await dataSource.getInterestsList();

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(defaultInterests));
        verify(mockRemoteConfig.getString('interests_list')).called(1);
      });

      test('should return default list when JSON decoding fails', () async {
        when(mockRemoteConfig.getString('interests_list')).thenReturn('invalid json');

        final result = await dataSource.getInterestsList();

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(defaultInterests));
        verify(mockRemoteConfig.getString('interests_list')).called(1);
      });
    });

    group('getAllowedDomains', () {
       test('should return decoded list when Remote Config provides valid JSON', () async {
        final domains = ['example.com', 'test.org'];
        when(mockRemoteConfig.getString('allowed_domains')).thenReturn(json.encode(domains));

        final result = await dataSource.getAllowedDomains();

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(domains));
        verify(mockRemoteConfig.getString('allowed_domains')).called(1);
      });

       test('should return default list when Remote Config returns empty string', () async {
         when(mockRemoteConfig.getString('allowed_domains')).thenReturn('');
         final result = await dataSource.getAllowedDomains();
         expect(result.isSuccess, isTrue);
         expect(result.getSuccess, equals(defaultAllowedDomains));
         verify(mockRemoteConfig.getString('allowed_domains')).called(1);
       });

      test('should return default list when Remote Config throws error', () async {
        when(mockRemoteConfig.getString('allowed_domains')).thenThrow(Exception('Config error'));
        final result = await dataSource.getAllowedDomains();
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(defaultAllowedDomains));
        verify(mockRemoteConfig.getString('allowed_domains')).called(1);
      });

      test('should return default list when JSON decoding fails', () async {
        when(mockRemoteConfig.getString('allowed_domains')).thenReturn('invalid json');
        final result = await dataSource.getAllowedDomains();
        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, equals(defaultAllowedDomains));
        verify(mockRemoteConfig.getString('allowed_domains')).called(1);
      });
    });

    group('isFeatureEnabled', () {
      test('should return true when feature flag is true (specific key)', () async {
        when(mockRemoteConfig.getBool('auth_v1_enabled')).thenReturn(true);

        final result = await dataSource.isFeatureEnabled('auth_v1');

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, isTrue);
        verify(mockRemoteConfig.getBool('auth_v1_enabled')).called(1);
      });

      test('should return false when feature flag is false (specific key)', () async {
        when(mockRemoteConfig.getBool('auth_v1_enabled')).thenReturn(false);

        final result = await dataSource.isFeatureEnabled('auth_v1');

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, isFalse);
        verify(mockRemoteConfig.getBool('auth_v1_enabled')).called(1);
      });

      test('should return true when feature flag is true (dynamic key)', () async {
        when(mockRemoteConfig.getBool('dynamic_feature_xyz')).thenReturn(true);

        final result = await dataSource.isFeatureEnabled('dynamic_feature_xyz');

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, isTrue);
        verify(mockRemoteConfig.getBool('dynamic_feature_xyz')).called(1);
      });

      test('should return false when feature flag is false (dynamic key)', () async {
        when(mockRemoteConfig.getBool('another_dynamic_feature')).thenReturn(false);

        final result = await dataSource.isFeatureEnabled('another_dynamic_feature');

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, isFalse);
        verify(mockRemoteConfig.getBool('another_dynamic_feature')).called(1);
      });

      test('should return false (default) when Remote Config throws error', () async {
        when(mockRemoteConfig.getBool(any)).thenThrow(Exception('Config error'));

        final result = await dataSource.isFeatureEnabled('some_feature');

        expect(result.isSuccess, isTrue);
        expect(result.getSuccess, isFalse); // Defaults to false on error
        verify(mockRemoteConfig.getBool('some_feature')).called(1);
      });
    });

    group('refreshConfig', () {
      test('should call fetchAndActivate and return success', () async {
        when(mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true); 

        final result = await dataSource.refreshConfig();

        expect(result.isSuccess, isTrue);
        verify(mockRemoteConfig.fetchAndActivate()).called(1);
      });

      test('should return failure when fetchAndActivate throws error', () async {
        final exception = Exception('Fetch failed');
        when(mockRemoteConfig.fetchAndActivate()).thenThrow(exception);

        final result = await dataSource.refreshConfig();

        expect(result.isFailure, isTrue);
        expect(result.getFailure, isA<ServerFailure>());
        expect(result.getFailure.message, contains('Fetch failed'));
        verify(mockRemoteConfig.fetchAndActivate()).called(1);
      });
    });
  });
} 