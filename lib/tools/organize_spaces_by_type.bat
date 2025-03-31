@echo off
echo ========================================================
echo  HIVE UI - Space Structure Migrator
echo ========================================================
echo.
echo This script will reorganize spaces in Firestore based on
echo their spaceType field, moving them into type-specific subcollections.
echo.
echo The new structure will be:
echo   - spaces/
echo     - student_organizations/spaces/
echo     - university_organizations/spaces/
echo     - campus_living/spaces/
echo     - fraternity_and_sorority/spaces/
echo     - other/spaces/
echo.
echo Starting in 3 seconds...
timeout /t 3 > nul

echo.
echo Running space reorganization tool...
echo.

flutter run -d windows lib/tools/organize_spaces_by_type.dart

echo.
echo Process completed.
echo. 