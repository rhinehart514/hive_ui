@echo off
echo ========================================================
echo  HIVE UI - Space Migration Cleanup
echo ========================================================
echo.
echo *** WARNING: This utility will DELETE spaces from the root
echo *** collection after verifying they exist in type-specific
echo *** subcollections. This operation is IRREVERSIBLE!
echo.
echo Only run this after you have verified migration success!
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

echo.
echo Running space cleanup tool...
echo.

flutter run -d windows lib/tools/cleanup_migrated_spaces.dart

echo.
echo Process completed.
echo.
pause 