# GTA Advanced 3D - Quick Setup & Run Guide

## Step 1: Download Godot 4.x

1. Visit https://godotengine.org/download
2. Download **Godot 4.x (Standard)** for your OS:
   - Windows: `Godot_v4.x.x-stable_win64.exe`
   - Linux: `Godot_v4.x.x-stable_linux.x86_64`
   - Mac: `Godot_v4.x.x-stable_macos.universal`

3. Extract or install Godot

---

## Step 2: Open Project in Godot

1. Run Godot executable
2. Click **Open Project**
3. Navigate to: `d:\GTA_LITE\GangsterTownAdventures\`
4. Click **Open**
5. Wait for Godot to load the project (30-60 seconds first time)

---

## Step 3: Run the Game

### Option A: Editor Play

1. Press **F5** or click the ▶️ **Play** button (top-right)
2. Game window opens in 3D
3. Play with keyboard/mouse

### Option B: Standalone Build

1. Go to **Project** → **Export**
2. Select target OS (Windows, Linux, Mac)
3. Click **Export Project**
4. Choose export location
5. Run the exported `.exe` or binary

---

## Step 4: Add Free Assets (Optional but Recommended)

### Download Free 3D Assets

#### Character Models

```
Download from:
- Sketchfab.com (search: "free character 3d model")
- OpenGameArt.org (search: "player character")
- Kenney.nl (search: "3d character")

Download formats: .glb, .gltf, .fbx
```

#### Vehicle Models

```
Download from:
- Sketchfab.com (search: "free car model")
- OpenGameArt.org (search: "vehicle")

Download formats: .glb, .gltf
```

#### Environment Assets

```
Download from:
- Sketchfab.com (search: "free city buildings")
- Kenney.nl (search: "3d buildings")

Download formats: .glb, .gltf
```

### Import Assets into Project

1. **Create folders** (if not exists):
   - `GangsterTownAdventures/assets/models/`
   - `GangsterTownAdventures/assets/textures/`
   - `GangsterTownAdventures/assets/audio/`

```
# Open project from command line
godot -e d:\GTA_LITE\GangsterTownAdventures

# Export to Windows (example)
godot --headless --export-debug "Windows Desktop" d:\GTA_LITE\GangsterTownAdventures\build\GangsterTownAdventures.exe

# Run exported game
d:\GTA_LITE\GangsterTownAdventures\build\GangsterTownAdventures.exe
```

## Step 5: Play the Game

### Controls

| Key            | Action             |
| -------------- | ------------------ |
| **W/A/S/D**    | Move               |
| **Space**      | Jump               |
| **Shift**      | Sprint             |
| **Mouse**      | Look around        |
| **E**          | Enter/Exit vehicle |
| **F**          | Melee attack       |
| **Left Mouse** | Shoot              |
| **Esc**        | Pause/Menu         |

### Game Objectives

1. **Explore** the 3D world
2. **Complete missions** for money
3. **Fight gangsters** and police
4. **Drive vehicles**
5. **Earn money** and upgrade weapons

---

## Troubleshooting

### Game Won't Open

- ✅ Ensure Godot 4.x is installed
- ✅ Check project path is correct
- ✅ Verify no files are corrupted

### No Graphics

- ✅ Update graphics drivers
- ✅ Check GPU supports OpenGL 3.3+
- ✅ Use "GL Compatibility" renderer (default)

### Performance Issues

- ✅ Lower resolution in settings
- ✅ Reduce draw distance
- ✅ Close background applications
- ✅ Update GPU drivers

### Missing Assets

- ✅ Download assets from recommended sources
- ✅ Place in `assets/` folder
- ✅ Restart Godot

---

## File Structure

```
d:\GTA_LITE\
├── GangsterTownAdventures/           ← THIS IS THE GAME PROJECT
│   ├── project.godot
│   ├── README.md
│   ├── assets/
│   │   ├── models/
│   │   ├── textures/
│   │   └── audio/
│   ├── scenes/
│   │   ├── main/
│   │   ├── player/
│   │   ├── vehicles/
│   │   ├── ai/
│   │   └── ui/
│   └── scripts/
│       ├── player/
│       ├── vehicles/
│       ├── ai/
│       ├── systems/
│       └── ui/
├── scripts/                  ← Old Python code (archived)
└── assets/                   ← Old 2D assets (archived)
```

---

## Next: Customization

### Add More NPCs

Edit `scripts/main.gd` - Modify spawn functions:

```gdscript
func spawn_npcs():
    for i in range(10):  # Change 5 to 10 for more NPCs
        var npc = npc_scene.instantiate()
        add_child(npc)
        npc.global_position = Vector3(randf_range(-50, 50), 1, randf_range(-50, 50))
```

### Change World Size

Edit `scripts/systems/settings.gd`:

```gdscript
const WORLD_SIZE = Vector3(1000, 100, 1000)  # Bigger world
```

### Add Custom Missions

Edit `scripts/systems/mission_system.gd`:

```gdscript
var missions = [
    {"title": "Your Mission", "description": "...", "reward": 500},
    # Add more here
]
```

---

## Performance Stats

| Metric     | Target  | Typical     |
| ---------- | ------- | ----------- |
| FPS        | 60+     | 65-144      |
| Memory     | < 2GB   | 800MB-1.5GB |
| World Size | 500x500 | Expandable  |
| NPCs       | 10-20   | 10+ spawned |

---

## Support Resources

- **Godot Official Docs:** https://docs.godotengine.org/
- **GDScript Guide:** https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/
- **Free Assets:** OpenGameArt.org, Sketchfab.com, Kenney.nl
- **Community:** Reddit: r/godot

---

## Quick Commands

```bash
# Open project from command line
godot -e d:\GTA_LITE\GangsterTownAdventures

# Export to Windows
godot --export-release Windows d:\GTA_LITE\build\game.exe

# Run exported game
d:\GTA_LITE\build\game.exe
```

---

**Version:** 1.0.0  
**Last Updated:** April 18, 2026  
**Status:** ✅ Ready to Play
