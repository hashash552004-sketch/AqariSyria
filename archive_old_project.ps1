$root = 'c:/Users/asus/Desktop/AqariSyria'
$backup = Join-Path $root 'old_project_backup'
New-Item -ItemType Directory -Force -Path $backup | Out-Null

$items = @(
    '.firebaserc',
    'app',
    'build.gradle',
    'database.rules.json',
    'firebase.json',
    'firestore.rules',
    'firestore_rules_copy.txt',
    'get_logs.ps1',
    'gradle',
    'gradle.properties',
    'gradlew',
    'gradlew.bat',
    'settings.gradle',
    'storage.rules'
)

foreach ($item in $items) {
    $src = Join-Path $root $item
    if (Test-Path $src) {
        $dst = Join-Path $backup $item
        if (Test-Path $dst) {
            if (Test-Path $dst -PathType Container) {
                Remove-Item $dst -Recurse -Force
            } else {
                Remove-Item $dst -Force
            }
        }
        Move-Item -LiteralPath $src -Destination $dst -Force
    }
}

Write-Host 'Archived old project files to:'
Write-Host $backup
