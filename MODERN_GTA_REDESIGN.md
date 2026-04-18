# GANGSTER TOWN ADVENTURES - MODERN GTA-STYLE REDESIGN
## Complete Technical Design Document v2.0

---

## IMPLEMENTATION STATUS ✅

**Last Updated**: Session Complete

### Completed Systems:
- ✅ **Core Architecture**: State machine, Event bus, Game manager
- ✅ **Player Controller**: GTA-style movement, combat, vehicle entry/exit
- ✅ **Vehicle System**: VehicleBody3D physics, multiple vehicle types
- ✅ **AI Systems**: Behavior tree, Civilian AI, Police AI, Gang AI
- ✅ **Traffic System**: Traffic manager, AI driving
- ✅ **World Generation**: City generator, Time/Weather system
- ✅ **Mission System**: Story missions, Side missions, Objectives
- ✅ **HUD**: Modern GTA-style interface

### New Files Created:
```
scripts/core/
  ├── state_machine.gd      - Generic FSM
  ├── state.gd              - Base State class
  ├── event_bus.gd          - Global signals
  └── game_manager.gd       - Central game state

scripts/actors/player/
  └── player_controller.gd  - GTA-style player

scripts/actors/npcs/
  ├── behavior_tree.gd      - BT implementation
  ├── npc_base.gd           - Base NPC class
  ├── civilian_ai.gd        - Civilian behavior
  ├── police_ai.gd          - Police with wanted response
  └── gang_ai.gd            - Gang territory AI

scripts/vehicles/
  ├── vehicle_base.gd       - VehicleBody3D controller
  ├── traffic_manager.gd    - Traffic spawning/roads
  └── traffic_ai.gd         - AI vehicle driving

scripts/world/
  ├── city_generator.gd     - Procedural city
  └── time_weather.gd       - Day/night, weather

scripts/systems/
  └── mission_manager.gd    - GTA-style missions

scripts/ui/
  └── hud_modern.gd         - Modern HUD

scripts/
  └── main_new.gd           - New main controller
```

---

## 1. OVERVIEW

This document outlines a complete redesign of the game to achieve modern GTA-style open-world gameplay with realistic graphics, physics, and AI systems. All existing systems will be replaced with new, production-quality implementations.

### Target Reference Games
- GTA V (character movement, physics, AI)
- GTA IV (vehicle physics, ragdoll)
- GTA San Andreas (mission structure, gangs)
- Saints Row series (combat, customization)

### Engine Configuration
- **Engine**: Godot 4.6+
- **Renderer**: Forward+ (desktop) / Mobile (fallback)
- **Physics**: Godot Physics (Jolt optional)
- **Resolution**: 1920x1080 @ 60 FPS (scalable)

---

## 2. NEW FOLDER STRUCTURE

```
GangsterTownAdventures/
├── project.godot
├── assets/
│   ├── audio/
│   │   ├── sfx/
│   │   ├── music/
│   │   └── voice/
│   ├── materials/
│   │   ├── characters/
│   │   ├── vehicles/
│   │   ├── environment/
│   │   └── fx/
│   ├── models/          # For imported .glb/.gltf
│   └── textures/
│       ├── characters/
│       ├── vehicles/
│       ├── environment/
│       └── ui/
├── scenes/
│   ├── actors/
│   │   ├── player/
│   │   │   └── player.tscn
│   │   ├── npcs/
│   │   │   ├── civilian.tscn
│   │   │   ├── police.tscn
│   │   │   └── gang_member.tscn
│   │   └── animals/
│   │       └── animal.tscn
│   ├── vehicles/
│   │   ├── car_sedan.tscn
│   │   ├── car_sports.tscn
│   │   ├── car_suv.tscn
│   │   ├── motorcycle.tscn
│   │   └── truck.tscn
│   ├── world/
│   │   ├── districts/
│   │   │   ├── downtown.tscn
│   │   │   ├── industrial.tscn
│   │   │   ├── residential.tscn
│   │   │   └── harbor.tscn
│   │   ├── props/
│   │   │   ├── street_furniture.tscn
│   │   │   └── buildings.tscn
│   │   └── main_world.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── pause_menu.tscn
│   │   ├── main_menu.tscn
│   │   └── mission_ui.tscn
│   ├── weapons/
│   │   ├── projectile.tscn
│   │   └── weapon_pickup.tscn
│   └── main.tscn
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd
│   │   ├── state_machine.gd
│   │   ├── object_pool.gd
│   │   └── event_bus.gd
│   ├── actors/
│   │   ├── player/
│   │   │   ├── player_controller.gd
│   │   │   ├── player_states.gd
│   │   │   ├── player_combat.gd
│   │   │   └── player_inventory.gd
│   │   ├── npcs/
│   │   │   ├── npc_base.gd
│   │   │   ├── civilian_ai.gd
│   │   │   ├── police_ai.gd
│   │   │   ├── gang_ai.gd
│   │   │   └── behavior_tree.gd
│   │   └── character_body.gd
│   ├── vehicles/
│   │   ├── vehicle_base.gd
│   │   ├── car_controller.gd
│   │   ├── motorcycle_controller.gd
│   │   ├── traffic_manager.gd
│   │   └── vehicle_damage.gd
│   ├── world/
│   │   ├── world_streamer.gd
│   │   ├── district_manager.gd
│   │   ├── time_weather.gd
│   │   └── city_generator.gd
│   ├── systems/
│   │   ├── mission_manager.gd
│   │   ├── wanted_system.gd
│   │   ├── economy_system.gd
│   │   ├── save_system.gd
│   │   ├── audio_manager.gd
│   │   └── vfx_system.gd
│   ├── ui/
│   │   ├── hud_controller.gd
│   │   ├── minimap.gd
│   │   └── menu_controller.gd
│   └── utils/
│       ├── constants.gd
│       ├── helpers.gd
│       └── character_builder.gd
└── data/
    ├── missions/
    ├── dialogue/
    └── config/
```

---

## 3. CHARACTER MODEL SPECIFICATION (NEW)

### 3.1 Realistic Human Proportions
```
Total Height: 1.80 meters (6 feet)
Head Height: 0.24m (1/7.5 of body - realistic adult)
Torso Length: 0.54m
Arm Length: 0.72m (fingertip to shoulder)
Leg Length: 0.90m (hip to sole)
Shoulder Width: 0.46m
Hip Width: 0.36m
```

### 3.2 Skeletal Rig (Humanoid Standard)
```
Root
├── Hips
│   ├── Spine
│   │   ├── Spine1
│   │   │   ├── Spine2
│   │   │   │   ├── Neck
│   │   │   │   │   └── Head
│   │   │   │   │       ├── LeftEye
│   │   │   │   │       └── RightEye
│   │   │   │   ├── LeftShoulder
│   │   │   │   │   └── LeftArm
│   │   │   │   │       └── LeftForeArm
│   │   │   │   │           └── LeftHand
│   │   │   │   │               ├── LeftHandThumb1-3
│   │   │   │   │               ├── LeftHandIndex1-3
│   │   │   │   │               ├── LeftHandMiddle1-3
│   │   │   │   │               ├── LeftHandRing1-3
│   │   │   │   │               └── LeftHandPinky1-3
│   │   │   │   └── RightShoulder (mirror)
│   ├── LeftUpLeg
│   │   └── LeftLeg
│   │       └── LeftFoot
│   │           └── LeftToeBase
│   └── RightUpLeg (mirror)
```

### 3.3 Character Visual Quality
- **Polygon Count**: 8,000-15,000 tris (LOD0)
- **Texture Resolution**: 2048x2048 (body), 1024x1024 (clothing)
- **Material System**: PBR (albedo, normal, roughness, metallic, AO)
- **Skin Shader**: Subsurface scattering approximation
- **Hair System**: Shell-based hair cards with alpha

### 3.4 Clothing System
```
Slots:
- Head: Hair, Hat, Glasses, Mask
- Upper: Shirt, Jacket, Vest
- Lower: Pants, Shorts, Skirt
- Feet: Shoes, Boots
- Accessories: Watch, Necklace, Rings
```

---

## 4. VEHICLE MODEL SPECIFICATION (NEW)

### 4.1 Vehicle Categories
```
SEDAN:
  - Length: 4.8m, Width: 1.8m, Height: 1.4m
  - Wheelbase: 2.8m
  - Mass: 1500kg
  - Top Speed: 180 km/h
  - Acceleration: 0-100 in 8s
  - Handling: Balanced

SPORTS CAR:
  - Length: 4.4m, Width: 2.0m, Height: 1.2m
  - Wheelbase: 2.5m
  - Mass: 1300kg
  - Top Speed: 280 km/h
  - Acceleration: 0-100 in 4s
  - Handling: Sharp, low grip at high speed

SUV:
  - Length: 5.0m, Width: 2.0m, Height: 1.9m
  - Wheelbase: 3.0m
  - Mass: 2200kg
  - Top Speed: 160 km/h
  - Acceleration: 0-100 in 10s
  - Handling: Heavy, high center of gravity

MOTORCYCLE:
  - Length: 2.2m, Width: 0.8m, Height: 1.1m
  - Wheelbase: 1.5m
  - Mass: 200kg
  - Top Speed: 250 km/h
  - Acceleration: 0-100 in 3.5s
  - Handling: Agile, lean-based steering

TRUCK:
  - Length: 6.5m, Width: 2.4m, Height: 2.8m
  - Wheelbase: 4.0m
  - Mass: 4000kg
  - Top Speed: 120 km/h
  - Acceleration: 0-100 in 15s
  - Handling: Sluggish, powerful brakes
```

### 4.2 Vehicle Visual Quality
- **Polygon Count**: 15,000-25,000 tris (LOD0)
- **Interior Detail**: Fully modeled dashboard, seats, steering wheel
- **Damage System**: Deformable panels, breakable glass, detachable parts
- **Lights**: PBR emissive headlights, brake lights, turn signals
- **Reflections**: Screen-space reflections on paint, glass

### 4.3 Physics Parameters
```gdscript
# VehicleBody3D Configuration
var engine_force_value := 400.0
var brake_force := 50.0
var steering_limit := 0.4  # radians
var steering_speed := 5.0

# Suspension
var suspension_travel := 0.2
var suspension_stiffness := 50.0
var damping_compression := 2.0
var damping_relaxation := 3.0

# Wheel Friction
var friction_slip := 1.0
var lateral_stiffness := 25.0
```

---

## 5. ANIMATION SYSTEM (AAA-STYLE)

### 5.1 Animation State Machine
```
┌─────────────────────────────────────────────────────────┐
│                    LOCOMOTION                           │
│  ┌─────┐  ┌──────┐  ┌─────┐  ┌────────┐  ┌──────┐     │
│  │Idle │──│ Walk │──│ Jog │──│ Sprint │──│ Stop │     │
│  └──┬──┘  └──┬───┘  └──┬──┘  └────┬───┘  └──────┘     │
│     │        │         │          │                     │
│     └────────┴─────────┴──────────┘                     │
│              BlendTree (speed-based)                    │
└─────────────────────────────────────────────────────────┘
          │              │               │
          ▼              ▼               ▼
    ┌──────────┐  ┌────────────┐  ┌──────────────┐
    │ ACTIONS  │  │  COMBAT    │  │   VEHICLE    │
    │ Jump     │  │ Aim        │  │ Enter/Exit   │
    │ Climb    │  │ Fire       │  │ Drive        │
    │ Roll     │  │ Reload     │  │ Passenger    │
    │ Cover    │  │ Melee      │  │ Shoot        │
    └──────────┘  └────────────┘  └──────────────┘
```

### 5.2 Animation Blending
- **Locomotion BlendSpace2D**: Forward/Backward × Strafe Left/Right
- **Upper/Lower Body Split**: Independent aiming while moving
- **Additive Layers**: Breathing, weapon sway, look-at IK
- **Transition Times**: 0.1s (combat), 0.2s (locomotion), 0.3s (vehicle)

### 5.3 Procedural Animation (IK)
```
- Foot IK: Ground alignment, step placement
- Hand IK: Weapon grips, door handles, cover placement
- Look-At IK: Head tracks targets, camera direction
- Spine IK: Lean into turns, look around corners
```

---

## 6. PLAYER CONTROLLER (NEW)

### 6.1 Movement System
```
States:
  - OnFoot (Idle, Walk, Jog, Sprint, Crouch, Jump)
  - InVehicle (Driver, Passenger)
  - InCover (Standing, Crouching, Blind Fire)
  - Swimming (Surface, Underwater)
  - Climbing (Ledge, Ladder)
  - Ragdoll (Hit, Fall, Explosion)

Physics:
  - Acceleration: 15 m/s² (walk), 25 m/s² (sprint)
  - Max Speed: 4 m/s (walk), 8 m/s (sprint)
  - Jump Force: 6.5 m/s initial velocity
  - Air Control: 30% of ground control
  - Gravity: -20 m/s²
```

### 6.2 Camera System
```
Third Person Orbit:
  - Default Distance: 3.5m
  - Sprint Distance: 5.0m
  - Aim Distance: 2.0m
  - Height Offset: 1.6m (eye level)
  - Collision: SpringArm3D with collision mask
  - FOV: 70° (normal), 50° (aim), 80° (sprint)

Transitions:
  - Smooth follow with 0.15s lag
  - Lock-on targeting support
  - Vehicle camera (chase, hood, bumper views)
```

### 6.3 Combat System
```
Weapons:
  - Melee: Fists, Bat, Knife (combo system)
  - Pistol: 17 rounds, 300 RPM, 25 damage
  - SMG: 30 rounds, 800 RPM, 18 damage
  - Assault Rifle: 30 rounds, 600 RPM, 32 damage
  - Shotgun: 8 rounds, 60 RPM, 15x8 pellets
  - Sniper: 5 rounds, 30 RPM, 150 damage

Mechanics:
  - Recoil pattern (vertical + horizontal spread)
  - Bullet drop (sniper only)
  - Penetration (material-based)
  - Cover system (snap-to, blind fire, lean)
```

---

## 7. VEHICLE CONTROLLER (NEW)

### 7.1 Physics Model
Using Godot's VehicleBody3D with enhanced parameters:
```gdscript
extends VehicleBody3D

# Engine
var max_rpm := 7000.0
var idle_rpm := 800.0
var gear_ratios := [3.5, 2.5, 1.8, 1.3, 1.0, 0.8]  # 6 gears
var final_drive := 3.7
var engine_power := 300.0  # Horsepower equivalent

# Transmission
var current_gear := 1
var clutch := 1.0
var automatic := true

# Aerodynamics
var drag_coefficient := 0.3
var frontal_area := 2.2  # m²
var downforce := 0.5

# Damage
var body_health := 1000.0
var engine_health := 500.0
var tire_health := [100.0, 100.0, 100.0, 100.0]
```

### 7.2 Damage System
```
Collision Zones:
  - Front: Engine damage, radiator leak
  - Sides: Door deformation, window break
  - Rear: Trunk damage, tail lights
  - Roof: Rollover damage
  - Undercarriage: Oil pan, exhaust

Visual Damage:
  - Panel deformation (vertex displacement)
  - Paint scratches (decal system)
  - Broken glass (particle + transparency)
  - Smoke/fire (particle systems)
  - Wheel damage (flat tire physics)
```

### 7.3 Entry/Exit System
```
Entry:
  1. Player approaches (within 2.5m)
  2. Prompt appears ("Press E to enter")
  3. Player animation: reach for door
  4. Door animation: open
  5. Player animation: enter vehicle
  6. Door animation: close
  7. Camera transition to vehicle cam
  8. Input mode switch to vehicle

Exit:
  1. Player presses exit key
  2. Check for obstacles (raycast)
  3. Door animation: open
  4. Player animation: exit
  5. Player placed beside vehicle
  6. Camera transition to third-person
  7. Input mode switch to on-foot
```

---

## 8. AI SYSTEM (NEW)

### 8.1 Behavior Tree Architecture
```
Root (Selector)
├── Combat (Sequence) [if hostile]
│   ├── Perceive Threat
│   ├── Evaluate Threat Level
│   ├── Select Response
│   │   ├── Attack (if advantage)
│   │   ├── Take Cover (if disadvantage)
│   │   ├── Flee (if critical)
│   │   └── Call Backup (if police)
│   └── Execute Action
├── Alert (Sequence) [if suspicious]
│   ├── Investigate Source
│   ├── Search Area
│   └── Return to Normal (timeout)
└── Idle (Selector) [default]
    ├── Wander (civilians)
    ├── Patrol (police)
    ├── Guard (gang territory)
    └── Work (context-based)
```

### 8.2 Perception System
```
Vision:
  - FOV: 120° (civilian), 140° (police), 100° (gang)
  - Range: 30m (civilian), 50m (police), 40m (gang)
  - Obstruction: Raycast-based occlusion

Hearing:
  - Gunshots: 80m radius
  - Explosions: 150m radius
  - Footsteps: 10m radius
  - Vehicle: 30m radius

Awareness:
  - Alert Level: 0-100
  - Decay Rate: 5/second
  - Thresholds: Suspicious (30), Alert (60), Combat (90)
```

### 8.3 Traffic AI
```
Lane System:
  - Road network with nodes and connections
  - Lane width: 3.5m
  - Speed limits per road type
  - Traffic light obedience

Behavior:
  - Follow lane waypoints
  - Maintain safe distance
  - Yield to pedestrians at crosswalks
  - React to player (horn, avoid, panic)
  - Emergency vehicle response (pull over)
```

### 8.4 Police AI
```
Wanted Levels:
  1★ - 2 officers on foot, search area
  2★ - 2 patrol cars, pursue
  3★ - 4 patrol cars, helicopter
  4★ - SWAT teams, roadblocks
  5★ - Military vehicles, no-fly zone
  6★ - Tanks, total lockdown

Tactics:
  - Pursuit driving (PIT maneuver)
  - Coordinated flanking
  - Spike strip deployment
  - Helicopter spotlight tracking
```

---

## 9. CITY/WORLD DESIGN (NEW)

### 9.1 District Layout
```
┌───────────────────────────────────────┐
│           HARBOR (Industrial)          │
│  Warehouses, Docks, Cranes, Ships     │
├───────────────┬───────────────────────┤
│   DOWNTOWN    │    FINANCIAL          │
│  Skyscrapers  │    Banks, Offices     │
│  Main Plaza   │    Stock Exchange     │
├───────────────┼───────────────────────┤
│  CHINATOWN    │    LITTLE ITALY       │
│  Markets      │    Restaurants        │
│  Temples      │    Social Clubs       │
├───────────────┼───────────────────────┤
│  RESIDENTIAL  │    SUBURBS            │
│  Apartments   │    Houses             │
│  Projects     │    Malls              │
├───────────────┴───────────────────────┤
│          INDUSTRIAL ZONE              │
│  Factories, Railyard, Power Plant     │
└───────────────────────────────────────┘
```

### 9.2 World Scale
```
Total Area: 2km × 2km (4 km²)
Road Network: 50km of roads
Buildings: 500+ unique structures
LOD Levels: 4 (50m, 150m, 400m, 1000m)
Draw Distance: 2000m (reduced at night)
```

### 9.3 Streaming System
```
Chunk Size: 128m × 128m
Load Distance: 384m (3 chunks)
Unload Distance: 512m
Async Loading: Background thread
Priority: Distance + Player direction
```

---

## 10. MISSION SYSTEM (NEW)

### 10.1 Mission Structure
```gdscript
class_name Mission
extends Resource

@export var id: String
@export var title: String
@export var description: String
@export var chapter: int
@export var prerequisites: Array[String]

@export var objectives: Array[MissionObjective]
@export var rewards: MissionRewards
@export var fail_conditions: Array[FailCondition]

@export var start_cutscene: String
@export var end_cutscene: String
@export var dialogue_file: String
```

### 10.2 Objective Types
```
- GOTO: Navigate to location
- KILL: Eliminate targets
- COLLECT: Gather items
- ESCORT: Protect NPC
- CHASE: Pursue target
- ESCAPE: Evade pursuers
- DEFEND: Protect location
- STEALTH: Avoid detection
- RACE: Complete course
- HACK: Interact with terminals
```

### 10.3 Chapter Progression
```
CHAPTER 1: "Fresh Off The Boat"
  - Tutorial missions
  - Meet key characters
  - Establish safe house
  - Reward: $5,000, Pistol

CHAPTER 2: "Making Connections"
  - First gang contact
  - Drug delivery missions
  - Police escape tutorial
  - Reward: $15,000, SMG

CHAPTER 3: "Territory Wars"
  - Gang warfare begins
  - Take over first territory
  - Rival gang introduction
  - Reward: $30,000, Safehouse

CHAPTER 4: "The Big Score"
  - Heist planning
  - Crew recruitment
  - Bank robbery
  - Reward: $100,000, Assault Rifle

CHAPTER 5: "Empire Building"
  - Business acquisition
  - Property management
  - Gang expansion
  - Reward: Properties, Vehicles

CHAPTER 6: "Endgame"
  - Final confrontation
  - Multiple endings
  - Epilogue
  - Reward: 100% Completion
```

---

## 11. OPTIMIZATION PLAN

### 11.1 Rendering
```
- Occlusion Culling: GPU-based
- LOD System: 4 levels per asset
- Impostor System: Billboard at distance
- Batching: Static + Dynamic
- Shadow Cascades: 4 (10m, 50m, 150m, 500m)
```

### 11.2 Physics
```
- Collision Layers: 8 layers (player, NPC, vehicle, world, projectile, trigger, water, debris)
- Sleeping Bodies: Auto-sleep after 2s idle
- CCD: Only for high-speed objects
- Simplified Collision: Convex hulls, not trimesh
```

### 11.3 AI
```
- LOD AI: Full behavior (50m), Simple (150m), Disabled (300m)
- Pooling: NPC recycling at distance
- Staggered Updates: 30 NPCs/frame max
- Navmesh: Pre-baked with runtime updates
```

### 11.4 Memory
```
- Texture Streaming: Load on demand
- Audio Streaming: Stream large files
- Asset Bundles: Per-district loading
- Object Pooling: Bullets, particles, NPCs
```

---

## 12. IMPLEMENTATION PRIORITY

### Phase 1: Core (Week 1-2)
1. New player controller with state machine
2. Basic vehicle physics (VehicleBody3D)
3. Simple world with test district
4. HUD fundamentals

### Phase 2: Gameplay (Week 3-4)
1. Combat system (weapons, damage)
2. Vehicle entry/exit
3. Basic NPC AI
4. Mission framework

### Phase 3: Content (Week 5-6)
1. Full city districts
2. Traffic system
3. Police AI
4. Story missions

### Phase 4: Polish (Week 7-8)
1. Visual effects
2. Audio system
3. Save/Load
4. Optimization

---

## 13. QUALITY TARGETS

### Visual
- Consistent art style (stylized realism)
- Dynamic lighting (day/night)
- Weather effects (rain, fog)
- Particle systems (dust, sparks, smoke)

### Audio
- 3D positional audio
- Dynamic music system
- Vehicle engine simulation
- Ambient soundscapes

### Gameplay
- Responsive controls (< 50ms input lag)
- 60 FPS minimum on mid-range hardware
- No loading screens within city
- Autosave every 5 minutes

---

*Document Version: 2.0*
*Last Updated: April 18, 2026*
*Engine Target: Godot 4.6*
