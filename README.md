# 🏙️ Gangster Town Adventures

**An open-world 3D action-adventure game built with Godot Engine 4.6.2**

Rise from a nobody to the underboss of the most powerful crime family in Gangster Town. Complete story missions, engage in street combat, steal vehicles, evade police, and take over the city — all in a fully explorable 3D open world.

---

## � v2.0 - Modern GTA Redesign

The game has been completely redesigned with modern GTA-style systems:

- **New Player Controller** - 8 states, realistic movement, smooth camera
- **New Vehicle System** - VehicleBody3D physics, 6 vehicle types
- **New AI System** - Behavior trees, civilians, police, gangs
- **New World Generation** - Procedural city with districts
- **New Mission System** - Story chapters, side missions, objectives
- **New Time/Weather** - Day/night cycle, 6 weather types
- **New HUD** - Modern interface with minimap

See [MODERN_GTA_REDESIGN.md](MODERN_GTA_REDESIGN.md) for technical details.

---

## 🎮 Features

### Story Campaign

- **10+ story missions** across 6 chapters with full narrative arc
- **Character dialogue system** with typewriter text and color-coded speakers
- **Memorable characters**: Rico, Marco, Don Vittorio, and more
- Story progression from street-level thug to crime underboss

### Open World

- Explorable 3D city with roads, buildings, parks, shops, and landmarks
- **Dynamic day/night cycle** with atmospheric lighting
- **6 weather types**: Clear, Cloudy, Overcast, Rain, Storm, Fog
- Procedural city generation with multiple districts
- Street lights, traffic lights, vegetation

### Combat System

- **5 weapon types**: Fists, Pistol, SMG, Rifle, Shotgun
- Ammo management and weapon switching
- Aiming system with zoom
- Muzzle flash, tracer rounds, and hit impact effects

### Vehicles

- **6 vehicle types**: Sedan, Sports, SUV, Truck, Motorcycle, Boat
- Realistic VehicleBody3D physics
- Automatic transmission
- Vehicle damage system
- NPC traffic with AI driving

### AI Systems

- **Police AI** — Patrol, chase, combat with 1-6★ wanted level response
- **Gang AI** — Territory-based enemies with group coordination
- **Civilian AI** — NPCs that wander, flee, and call police
- **Traffic AI** — AI drivers following road rules

### Modern HUD

- Health and armor bars
- Money display with animations
- Wanted level stars
- Weapon and ammo display
- Real-time minimap
- Mission objectives

### Sound & Audio

- Procedural sound effects
- Radio system with multiple stations
- Mission completion fanfare

### Save/Load System

- Save progress at any time (Alt+S)
- Load saved game (Alt+L)
- Persistent money, stats, and mission progress

---

## 🕹️ Controls

| Action             | Key               |
| ------------------ | ----------------- |
| Move               | W / A / S / D     |
| Look Around        | Mouse             |
| Sprint             | Shift             |
| Jump               | Space             |
| Shoot              | Left Mouse Button |
| Melee Attack       | F                 |
| Enter/Exit Vehicle | E                 |
| Switch Weapon      | 1 / 2 / 3 / 4     |
| Start Mission      | M                 |
| Save Game          | Alt + S           |
| Load Game          | Alt + L           |
| Pause              | Escape            |

---

## 📖 Story Synopsis

**Chapter 1: The Newcomer**
You arrive in Gangster Town to meet your cousin Marco. The streets are dangerous, and the Red Vipers gang runs the show. Time to prove yourself.

**Chapter 2: Rising Heat**
Marco introduces you to the criminal underworld. Steal cars, evade police, and build your reputation on the streets.

**Chapter 3: The Organization**
Don Vittorio, the city's most powerful crime boss, takes notice. He offers you a place in his organization — but loyalty comes at a price.

**Chapter 4: The War**
A bank heist goes right, but war with the Red Vipers is inevitable. Defend your territory and prepare for the final showdown.

**Chapter 5: The Final Showdown**
Everything leads to this. Take down Snake Eye and his elite soldiers in an all-out battle for control of Gangster Town.

---

## 🚀 Quick Start

### Play from Source

1. Download and install [Godot 4.6+](https://godotengine.org/download) (Standard version)
2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/gangster-town-adventures.git
   ```
3. Open Godot → **Open Project** → Navigate to `GangsterTownAdventures/project.godot` (project folder is `GangsterTownAdventures/` in the repo root)
4. Press **F5** to play!

### Build Executable

See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for detailed build and distribution steps. A built Windows executable is available in `GangsterTownAdventures/build/` after export.

---

## 🏗️ Project Structure

```
GangsterTownAdventures/
├── project.godot              # Godot project configuration
├── export_presets.cfg         # Export settings for Windows build
├── scenes/
│   ├── main/main.tscn        # Main game scene
│   ├── ui/main_menu.tscn     # Start menu
│   ├── player/bullet.tscn    # Bullet projectile
│   ├── ai/                   # NPC scenes (police, gangster, pedestrian, animal)
│   └── vehicles/             # Vehicle scenes (car, motorcycle, traffic)
├── scripts/
│   ├── main.gd               # Game initialization and spawning
│   ├── globals.gd            # Global state manager (autoload)
│   ├── player/
│   │   ├── player.gd         # Player controller (3rd person)
│   │   └── bullet.gd         # Projectile physics
│   ├── ai/
│   │   ├── police.gd         # Police AI (patrol/chase/arrest)
│   │   ├── gangster.gd       # Gang AI (provocation-based combat)
│   │   ├── pedestrian.gd     # Civilian NPC AI
│   │   ├── traffic.gd        # Traffic car AI
│   │   └── animal.gd         # Dog/cat AI
│   ├── vehicles/
│   │   ├── vehicle.gd        # Drivable car controller
│   │   └── motorcycle.gd     # Motorcycle/bicycle controller
│   ├── systems/
│   │   ├── story_missions.gd # 10 story missions with dialogue
│   │   ├── dialogue_system.gd# Typewriter dialogue UI
│   │   ├── sfx_manager.gd    # Procedural sound effects
│   │   ├── save_load.gd      # JSON save/load system
│   │   ├── economy.gd        # Money management
│   │   ├── weapon_pickup.gd  # Weapon/ammo pickups
│   │   └── settings.gd       # Game settings
│   ├── ui/
│   │   ├── hud.gd            # In-game HUD overlay
│   │   ├── main_menu.gd      # Main menu screen
│   │   └── minimap.gd        # Minimap display
│   ├── world/
│   │   └── environment.gd    # City builder (roads, buildings, etc.)
│   └── utils/
│       └── character_model.gd # Procedural humanoid builder
```

---

## ⚙️ Technical Details

- **Engine:** Godot 4.6.2 (GDScript 2.0)
- **Renderer:** OpenGL Compatibility (wide GPU support)
- **Resolution:** 1920×1080 (windowed)
- **Physics:** Godot Physics 3D
- **Character Models:** Procedural humanoids built from primitive meshes
- **Audio:** Real-time procedural sound generation (no external audio files)

## 🛠️ Technologies Used
---

## Build & Distribution (Git LFS and Releases)

The Windows build (`GangsterTownAdventures.exe`) is exported to `GangsterTownAdventures/build/`.

Because the build is larger than GitHub's 100 MB limit, the repository uses Git LFS for the executable. Current status:

- The `build/GangsterTownAdventures.exe` file is tracked with Git LFS in branch `Dev`.
- Git LFS objects were uploaded and the `Dev` branch was rewritten to store the file as an LFS pointer.

If you prefer distributing builds via GitHub Releases (recommended for public downloads), create a release and attach the `.exe` as an asset instead of committing it to the repository.

Quick commands — create a release with GitHub CLI:

```powershell
git tag v1.0.0
git push origin v1.0.0
gh release create v1.0.0 GangsterTownAdventures/build/GangsterTownAdventures.exe --title "v1.0.0" --notes "Windows build"
```

### Why we used Git LFS

- Keeps repository small for source history while storing large binary artifacts separately.
- Collaborators must have `git-lfs` installed to fetch LFS objects.

## Collaborator: How to sync this repo (after LFS changes)

If you've cloned before the LFS migration or haven't pulled the new `Dev` branch, run:

```powershell
git lfs install
git fetch origin
git checkout Dev
# Make sure you match remote exactly if history was rewritten
git reset --hard origin/Dev
git lfs pull
```

Notes:
- The `reset --hard` is necessary if the branch history was rewritten (force-pushed). This will discard local divergent commits — stash or backup first if needed.

## Where to modify the game (quick guide)

- Player controller & camera: `scripts/player/player.gd` — modify movement, camera pivoting, visibility handling.
- Game startup and intro: `scripts/main.gd` — spawn counts, intro flow, mission initialization.
- Mission definitions & timers: `scripts/systems/story_missions.gd` — edit missions, objectives, rewards, and `get_time_remaining()` logic.
- Vehicles: `scripts/vehicles/vehicle.gd` and `scripts/vehicles/motorcycle.gd` — entry/exit logic, physics tuning.
- HUD and UI: `scripts/ui/hud.gd`, `scripts/ui/minimap.gd`, `scripts/ui/main_menu.gd` — HUD layout, minimap POIs, menu options.
- Save/load behaviour: `scripts/systems/save_load.gd` — serialization and safety checks.
- Audio: `scripts/systems/sfx_manager.gd` and `scripts/systems/radio_system.gd` — procedural SFX and radio stations.

Open those files in the `scripts/` folder and edit with Godot or a code editor. After changes, run the game in Godot (F5) to test.

## Shortcut & Icon

- A desktop shortcut script `create_shortcut.ps1` exists and now references `build/GangsterTownAdventures.ico`.
- The icon was generated and saved to `GangsterTownAdventures/build/GangsterTownAdventures.ico` during packaging.

To recreate the shortcut manually, run:

```powershell
.\create_shortcut.ps1
```

## Next steps & recommendations

- For public distribution, publish a GitHub Release and attach the `.exe` so downloads don't rely on LFS.
- Keep large binary artifacts out of the main branch if you prefer a small repo — use Releases or an external storage bucket.
- Add CI to build and upload release artifacts automatically (GitHub Actions recommended). See `BUILD_NOTES.md` for export commands.


- **Godot Engine:** 4.6.2 (editor & export templates)
- **Scripting:** GDScript 2.0 (Godot native scripting)
- **Rendering:** OpenGL Compatibility profile (recommended for broad GPU support)
- **Build & Export:** Godot Export Templates (Windows Desktop build)
- **Version Control:** Git (recommended)
- **Platform Tools:** PowerShell for Windows automation and shortcuts

---

## 📋 System Requirements

|             | Minimum               |
| ----------- | --------------------- |
| **OS**      | Windows 10 (64-bit)   |
| **GPU**     | OpenGL 3.3 compatible |
| **RAM**     | 2 GB                  |
| **Storage** | 50 MB                 |
| **Input**   | Keyboard + Mouse      |

---

## 📝 License

This project is open source. Feel free to modify and distribute.

---

## 🙏 Credits

- Built with [Godot Engine 4.6](https://godotengine.org/)
- All game assets are procedurally generated (no external assets required)
- Sound effects generated at runtime using Godot's audio system

---

_Gangster Town Adventures — From nobody to kingpin. The streets are yours._
