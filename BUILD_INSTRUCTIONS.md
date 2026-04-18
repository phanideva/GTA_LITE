# How to Build & Distribute Gangster Town Adventures

## Quick Play (Development)
1. Install Godot 4.6+ from https://godotengine.org/download
2. Open Godot → Import Project → Select `godot_project/project.godot`
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
```bash
# Make sure Godot is in your PATH
godot --headless --export-release "Windows Desktop" build/GangsterTownAdventures.exe
```

## Distribution
After building, share these files:
- `GangsterTownAdventures.exe` — Main game executable
- `GangsterTownAdventures.pck` — Game data (if not embedded)

### Creating a ZIP Package
```powershell
# From the godot_project folder after exporting:
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
