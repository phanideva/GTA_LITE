# 🏙️ Gangster Town Adventures

**An open-world 3D action-adventure game built with Godot Engine 4.6**

Rise from a nobody to the underboss of the most powerful crime family in Gangster Town. Complete story missions, engage in street combat, steal vehicles, evade police, and take over the city — all in a fully explorable 3D open world.

---

## 🎮 Features

### Story Campaign
- **10 story missions** across 5 chapters with full narrative arc
- **Character dialogue system** with typewriter text and color-coded speakers
- **Memorable characters**: Rico, Marco, Don Vittorio, and more
- Story progression from street-level thug to crime underboss

### Open World
- Explorable 3D city with roads, buildings, parks, shops, and landmarks
- Dynamic day/night cycle with atmospheric lighting
- 50+ trees, streetlights, benches, dumpsters, and environmental details
- 8 unique shop locations across the city

### Combat System
- **4 weapon types**: Fists, Pistol, Rifle, Shotgun
- Ammo management and weapon switching (keys 1-4)
- Muzzle flash, tracer rounds, and hit impact effects
- Melee combat with area-of-effect damage

### Vehicles
- **Cars** — Fully drivable with acceleration, braking, and steering
- **Motorcycles** — Lean-into-turns physics
- **Bicycles** — Pedal-powered with realistic speed
- NPC traffic with AI-driven patrol cars

### AI Systems
- **Police AI** — Patrol, chase, shoot, and arrest based on wanted level (1-6 stars)
- **Gang AI** — Territory-based enemies that only attack when provoked
- **Pedestrians** — Civilian NPCs that wander the city and flee from danger
- **Animals** — Dogs and cats with wander/flee behavior

### Sound & Audio
- Procedural sound effects (gunshots, melee, sirens, pickups, death)
- Different audio for each weapon type
- Mission completion fanfare

### Save/Load System
- Save progress at any time (Alt+S)
- Load saved game (Alt+L)
- Persistent money, stats, and mission progress

---

## 🕹️ Controls

| Action | Key |
|--------|-----|
| Move | W / A / S / D |
| Look Around | Mouse |
| Sprint | Shift |
| Jump | Space |
| Shoot | Left Mouse Button |
| Melee Attack | F |
| Enter/Exit Vehicle | E |
| Switch Weapon | 1 / 2 / 3 / 4 |
| Start Mission | M |
| Save Game | Alt + S |
| Load Game | Alt + L |
| Pause | Escape |

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
3. Open Godot → **Import** → Navigate to `godot_project/project.godot`
4. Press **F5** to play!

### Build Executable
See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for detailed build and distribution steps.

---

## 🏗️ Project Structure

```
godot_project/
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

- **Engine:** Godot 4.6 (GDScript 2.0)
- **Renderer:** OpenGL Compatibility (wide GPU support)
- **Resolution:** 1920×1080 (windowed)
- **Physics:** Godot Physics 3D
- **Character Models:** Procedural humanoids built from primitive meshes
- **Audio:** Real-time procedural sound generation (no external audio files)

---

## 📋 System Requirements

| | Minimum |
|---|---|
| **OS** | Windows 10 (64-bit) |
| **GPU** | OpenGL 3.3 compatible |
| **RAM** | 2 GB |
| **Storage** | 50 MB |
| **Input** | Keyboard + Mouse |

---

## 📝 License

This project is open source. Feel free to modify and distribute.

---

## 🙏 Credits

- Built with [Godot Engine 4.6](https://godotengine.org/)
- All game assets are procedurally generated (no external assets required)
- Sound effects generated at runtime using Godot's audio system

---

*Gangster Town Adventures — From nobody to kingpin. The streets are yours.*