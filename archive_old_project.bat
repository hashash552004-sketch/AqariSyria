@echo off
set ROOT=%~dp0
set BACKUP=%ROOT%old_project_backup
if not exist "%BACKUP%" mkdir "%BACKUP%"

for %%F in (".firebaserc" "app" "build.gradle" "database.rules.json" "firebase.json" "firestore.rules" "firestore_rules_copy.txt" "get_logs.ps1" "gradle" "gradle.properties" "gradlew" "gradlew.bat" "settings.gradle" "storage.rules") do (
  if exist "%ROOT%%%~F" (
    if exist "%BACKUP%%%~F" (
      rd /s /q "%BACKUP%%%~F"
    )
    move "%ROOT%%%~F" "%BACKUP%%%~F" >nul
  )
)

echo Archived old project files to %BACKUP%
dir /b "%ROOT%"
