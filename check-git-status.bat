@echo off
echo ========================================
echo  CHECKING GIT STATUS
echo ========================================
echo.

cd /d "%~dp0"

echo Git Status:
git status

echo.
echo ========================================
echo Recent Commits:
git log --oneline -5

echo.
echo ========================================
echo Files Changed in Last Commit:
git diff HEAD~1 --name-only

echo.
pause

