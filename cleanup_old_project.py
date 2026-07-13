import shutil
from pathlib import Path

root = Path(r'c:/Users/asus/Desktop/AqariSyria')
backup = root / 'old_project_backup'
backup.mkdir(exist_ok=True)

items = [
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
    'storage.rules',
]

for name in items:
    src = root / name
    if not src.exists():
        continue
    dst = backup / name
    if dst.exists():
        if dst.is_dir():
            shutil.rmtree(dst)
        else:
            dst.unlink()
    shutil.move(str(src), str(dst))

print('Archived old project files to', backup)
for p in sorted(root.iterdir()):
    print(p.name)
