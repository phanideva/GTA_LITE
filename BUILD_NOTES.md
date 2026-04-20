BUILD NOTES — Gangster Town Adventures
=====================================

This file contains practical build, export, and release instructions for maintainers.

1) Export Windows build (local Godot)

- Ensure you have Godot 4.6.x with export templates installed.
- Open the project in Godot and verify `export_presets.cfg` exists (it does).
- From command line (headless export using the Godot console executable):

```powershell
# Example (adjust path to Godot executable if needed):
d:\GTA_LITE\GodotEngine\Godot_v4.6.2-stable_win64_console.exe --headless --path "d:\GTA_LITE\GangsterTownAdventures" --export-release "Windows Desktop" "build/GangsterTownAdventures.exe"
```

2) Create desktop shortcut and icon (automated)

- `create_shortcut.ps1` exists in the repo root and will create a desktop shortcut pointing to `build/GangsterTownAdventures.exe` and set the icon to `build/GangsterTownAdventures.ico`.
- Run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\create_shortcut.ps1
```

3) Distribution options

- Git LFS (current): the `build/` exe is tracked by Git LFS. Collaborators must run `git lfs install` and `git lfs pull` after syncing.
- GitHub Release (recommended): publish a release and upload the exported `.exe` as an asset for easy downloads.

4) CI suggestion (GitHub Actions)

- Add a workflow that runs Godot headless export on push to `Dev` or `main`, then uploads the built artifact to Releases or to the repo `build/` (if you choose that policy).

5) Notes about repository history

- We migrated the `Dev` branch to store the `build/` executable in LFS. If you had a local clone before this migration, follow the README instructions to `reset --hard origin/Dev` and `git lfs pull`.
