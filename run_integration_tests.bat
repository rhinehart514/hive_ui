@echo off
echo Running HIVE UI Integration Tests...
echo ====================================

rem Run each test individually
echo Running Onboarding Test...
flutter drive --driver=integration_test/test_driver.dart --target=integration_test/onboarding_test.dart

echo Running Profile Management Test...
flutter drive --driver=integration_test/test_driver.dart --target=integration_test/profile_management_test.dart

echo Running Spaces Test...
flutter drive --driver=integration_test/test_driver.dart --target=integration_test/spaces_test.dart

echo Running Events Test...
flutter drive --driver=integration_test/test_driver.dart --target=integration_test/events_test.dart

echo Running Content Test...
flutter drive --driver=integration_test/test_driver.dart --target=integration_test/content_test.dart

echo ====================================
echo All integration tests completed! 