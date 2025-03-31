@echo off
echo ========================================
echo    HIVE UI - Initialize All Clubs
echo ========================================
echo.
echo This script will initialize all clubs in Firestore with proper branch structure:
echo   - Campus Living Branch
echo   - Fraternity & Sorority Life Branch
echo   - Student Organizations
echo   - University Departments
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul

cd ..
flutter run -d windows tool/init_all_clubs.dart

echo.
echo Process completed.
echo.
pause 