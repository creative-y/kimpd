@echo off
chcp 65001 >nul
title kimpd 깃허브 배포
cd /d "%~dp0"

set "BASH="
rem 1) 설치된 git 위치에서 bash.exe 유추 (어디에 깔려 있든 따라감)
for /f "delims=" %%G in ('where git 2^>nul') do (
  if not defined BASH if exist "%%~dpG..\bin\bash.exe" set "BASH=%%~dpG..\bin\bash.exe"
)
rem 2) 표준 설치 경로
if not defined BASH if exist "C:\Program Files\Git\bin\bash.exe" set "BASH=C:\Program Files\Git\bin\bash.exe"
if not defined BASH if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "BASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not defined BASH if exist "C:\Program Files (x86)\Git\bin\bash.exe" set "BASH=C:\Program Files (x86)\Git\bin\bash.exe"

if not defined BASH (
  echo.
  echo   Git Bash를 찾지 못했습니다.
  echo   https://git-scm.com/download/win 에서 설치한 뒤 다시 실행하세요.
  echo.
  pause
  exit /b 1
)

echo   Git Bash : %BASH%
"%BASH%" "%~dp0deploy.sh" %*
