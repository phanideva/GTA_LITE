# How to Build & Distribute Gangster Town Adventures

## Quick Play (Development)

1. Install Godot 4.6+ from https://godotengine.org/download
2. Open Godot → Open Project → Select `GangsterTownAdventures/project.godot`
3. Press F5 (Play) to launch the game

## Build Executable (Windows)

### Option A: Using Godot Editor

1. Open the project in Godot 4.6+
2. Go to **Project → Export**
3. Select **Windows Desktop** preset (already configured)
4. Click **Export Project**
5. Choose output folder → Save as `GangsterTownAdventures.exe`
6. The `.exe` and `.pck` files are your distributable game!

### Option B: Command Line

```powershell
# Make sure Godot is in your PATH (or use full path to Godot executable)
godot --headless --export-debug "Windows Desktop" "build/GangsterTownAdventures.exe"
```

Note: Export templates for Godot 4.6 must be installed (usually under `%APPDATA%\Godot\export_templates\4.6.2.stable`). If export fails, install the official export templates from the Godot release page.

## Distribution

After building, share these files from the `GangsterTownAdventures/build/` folder:

- `GangsterTownAdventures.exe` — Main game executable
- `GangsterTownAdventures.pck` — Game data (if not embedded)

Tip: A desktop shortcut is created/updated by the build scripts to point to the `build\GangsterTownAdventures.exe` (on Windows this will appear on the current user's Desktop as "Gangster Town Adventures.lnk").

### Creating a ZIP Package

```powershell
# From the GangsterTownAdventures folder after exporting:
Compress-Archive -Path build/* -DestinationPath GangsterTownAdventures-v1.0-Windows.zip
```

## System Requirements

- **OS:** Windows 10/11 (64-bit)
- **GPU:** Any GPU with OpenGL 3.3+ support
- **RAM:** 2 GB minimum
- **Storage:** ~50 MB
- **Input:** Keyboard + Mouse

## Troubleshooting

- If the game won't start, install the [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)
- If graphics look wrong, update your GPU drivers
- For best performance, close other GPU-intensive applications
