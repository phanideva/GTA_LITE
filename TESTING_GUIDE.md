# GTA Advanced 3D - Testing & Verification Guide

## ✅ Pre-Launch Checklist

Run through this checklist before playing the game for the first time.

### 1. Environment Setup
- [ ] Godot 4.x installed
- [ ] Project folder exists: `d:\GTA_LITE\godot_project\`
- [ ] All script files present in `scripts/` folder
- [ ] All scene files present in `scenes/` folder
- [ ] `project.godot` config file exists

### 2. File Verification

**Core Script Files (Required):**
- [ ] `scripts/globals.gd`
- [ ] `scripts/systems/settings.gd`
- [ ] `scripts/systems/mission_system.gd`
- [ ] `scripts/systems/economy.gd`
- [ ] `scripts/systems/save_load.gd`
- [ ] `scripts/player/player.gd`
- [ ] `scripts/player/bullet.gd`
- [ ] `scripts/vehicles/vehicle.gd`
- [ ] `scripts/ai/pedestrian.gd`
- [ ] `scripts/ai/police.gd`
- [ ] `scripts/ai/gangster.gd`
- [ ] `scripts/ai/traffic.gd`
- [ ] `scripts/ui/hud.gd`
- [ ] `scripts/ui/minimap.gd`
- [ ] `scripts/ui/main_menu.gd`
- [ ] `scripts/world/environment.gd`
- [ ] `scripts/main.gd`

**Scene Files (Required):**
- [ ] `scenes/main/main.tscn`
- [ ] `scenes/player/bullet.tscn`
- [ ] `scenes/vehicles/vehicle.tscn`
- [ ] `scenes/vehicles/traffic.tscn`
- [ ] `scenes/ai/pedestrian.tscn`
- [ ] `scenes/ai/police.tscn`
- [ ] `scenes/ai/gangster.tscn`
- [ ] `scenes/ui/main_menu.tscn`

### 3. Asset Folders
- [ ] `assets/models/` folder exists
- [ ] `assets/textures/` folder exists
- [ ] `assets/audio/` folder exists

---

## 🚀 Launch Instructions

### Step 1: Open Project
1. Launch Godot 4.x
2. Click **Open Project**
3. Navigate to: `d:\GTA_LITE\godot_project\`
4. Click **Open**

### Step 2: Wait for Import
- Godot imports all scenes and scripts
- First launch takes 30-60 seconds
- Watch for import progress in bottom-right

### Step 3: Play
- Press **F5** or click Play (▶️) button
- Game window opens with 3D world
- Player spawns in center of world

---

## 🧪 Testing Matrix

### Test 1: Basic Startup
```
Objective: Verify game launches without errors
Expected: Game window opens, no crash
Steps:
1. Launch Godot
2. Open project
3. Press F5
4. Wait 5 seconds

✅ PASS: Game running with player visible
❌ FAIL: Crash, black screen, or errors in console
```

### Test 2: Player Movement
```
Objective: Verify WASD movement works
Expected: Player moves in 3D space
Steps:
1. Press W - Move forward
2. Press A - Move left
3. Press S - Move back
4. Press D - Move right
5. Press Space - Jump

✅ PASS: Player moves smoothly in all directions
❌ FAIL: Player doesn't move or moves wrongly
```

### Test 3: Camera Control
```
Objective: Verify mouse look works
Expected: Camera rotates with mouse
Steps:
1. Move mouse left/right - Look around
2. Move mouse up/down - Look up/down

✅ PASS: Camera follows mouse smoothly
❌ FAIL: Mouse doesn't work or behaves strangely
```

### Test 4: NPC Spawning
```
Objective: Verify NPCs appear in world
Expected: See pedestrians, police, gangsters walking around
Steps:
1. Look around world
2. Count visible NPCs

✅ PASS: Multiple NPCs visible, moving around
❌ FAIL: No NPCs visible or crash
```

### Test 5: Vehicle System
```
Objective: Verify vehicle entry/driving works
Expected: Can enter and drive car
Steps:
1. Find vehicle (gray box)
2. Press E near it (should interact)
3. Once inside, use WASD to drive
4. Press E to exit

✅ PASS: Enter car, drive, exit successfully
❌ FAIL: Can't enter, drive broken, or crash
```

### Test 6: Combat System
```
Objective: Verify shooting and melee work
Expected: Can shoot and punch NPCs
Steps:
1. Find NPC
2. Press F - Melee attack (should punch)
3. Press LMB - Shoot (should fire)
4. NPC should take damage

✅ PASS: Attacks work, NPC reacts
❌ FAIL: No damage, no effects
```

### Test 7: Mission System
```
Objective: Verify missions can be started
Expected: Mission objectives display in HUD
Steps:
1. In game, press Space (or check for mission button)
2. Mission should appear in HUD
3. Mission objective should display

✅ PASS: Mission starts, HUD shows objective
❌ FAIL: No mission, or HUD not updating
```

### Test 8: HUD Display
```
Objective: Verify all HUD elements display
Expected: See health, money, wanted level, FPS
Steps:
1. Look at top-left of screen
2. Should see: Health, Money labels
3. Look at top-right
4. Should see: Wanted level (★ stars)
5. Look at bottom-right
6. Should see: FPS counter

✅ PASS: All HUD elements visible and updating
❌ FAIL: Missing HUD elements or not updating
```

### Test 9: Minimap
```
Objective: Verify minimap displays
Expected: Small map showing player position
Steps:
1. Look at screen edge (usually top-left)
2. Should see: Small square with player marker

✅ PASS: Minimap visible with player dot
❌ FAIL: No minimap visible
```

### Test 10: Save/Load
```
Objective: Verify save system works
Expected: Can save and load game
Steps:
1. Get money in game
2. Press Ctrl+S - Save game
3. Check console: "Game saved!" message
4. Move player to new location
5. Press Ctrl+L - Load game
6. Player should return to saved location

✅ PASS: Save created, game loads at saved location
❌ FAIL: Save fails or load doesn't work
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Game Won't Start
**Symptoms:** Crash on launch, black screen, or error message

**Solutions:**
1. Verify all script files exist
2. Check console (F8) for error messages
3. Ensure project.godot is in correct location
4. Try closing and reopening Godot
5. Verify Godot version is 4.x (not 3.x)

### Issue 2: Player Can't Move
**Symptoms:** WASD keys do nothing

**Solutions:**
1. Verify input map is configured (Project → Project Settings → Input Map)
2. Check player script is attached to CharacterBody3D node
3. Verify no collision issues (Player falling through ground = collision problem)
4. Check console for scripting errors

### Issue 3: Visible Frame Rate Drop
**Symptoms:** Game runs below 30 FPS

**Solutions:**
1. Reduce NPC spawn count in main.gd (change from 5 to 3)
2. Reduce world size in settings.gd
3. Lower render resolution (Project → Project Settings → Display)
4. Close other applications
5. Update graphics drivers

### Issue 4: NPCs Not Appearing
**Symptoms:** World is empty, no pedestrians/police

**Solutions:**
1. Verify scene files exist: `scenes/ai/pedestrian.tscn`, etc.
2. Check main.gd spawn functions are called
3. Look for errors in console (F8)
4. Verify physics bodies are set correctly in scenes

### Issue 5: Can't Enter Vehicles
**Symptoms:** Pressing E near car does nothing

**Solutions:**
1. Verify vehicle.tscn scene is correct
2. Check collision shapes exist on vehicle
3. Verify player is in group "vehicle"
4. Try pressing E at different distances
5. Check console for interaction errors

### Issue 6: Graphics Issues
**Symptoms:** Blurry, glitchy, or missing graphics

**Solutions:**
1. Update graphics drivers
2. Check GPU supports OpenGL 3.3+
3. Verify "GL Compatibility" renderer is selected
4. Try lowering render resolution
5. Disable HDR if causing issues

---

## 📊 Expected Performance

### Target Hardware
- **GPU:** NVIDIA GTX 1060 or equivalent
- **CPU:** Intel i5-8400 or equivalent
- **RAM:** 8GB

### Performance Metrics
| Metric | Expected | Acceptable |
|--------|----------|------------|
| FPS | 60+ | 30+ |
| Frametime | 16ms | 33ms |
| Memory | 1-1.5GB | <2GB |
| Load Time | 5-10s | <15s |

### Performance Optimization Tips
1. **If FPS < 30:**
   - Reduce NPC count (edit main.gd)
   - Lower render resolution
   - Close background apps

2. **If FPS < 60:**
   - Disable minimap temporarily
   - Reduce world size
   - Update graphics drivers

---

## 🔍 Debug Mode

### Accessing Debug Console
Press **F8** in Godot editor

### Useful Debug Commands
```gdscript
# Print player position
print("Player pos: ", Globals.player.global_position)

# Print NPC count
print("NPCs: ", get_tree().get_nodes_in_group("npc").size())

# Print money
print("Money: $", Globals.player_money)

# Print wanted level
print("Wanted: ", Globals.wanted_level)

# Check if game is running
print("Game state: ", Globals.game_state)
```

### Viewing Errors
1. Press F8 to open debugger
2. Look at "Errors" tab
3. Red text = error, Yellow = warning
4. Click error to jump to source

---

## ✨ Verification Checklist (Final)

Before considering game complete, verify:

**Functionality:**
- [ ] All 10 tests above PASS
- [ ] No crashes after 30 minutes of play
- [ ] All systems responding correctly
- [ ] Save/Load works reliably

**Performance:**
- [ ] Maintains 60+ FPS (target hardware)
- [ ] No memory leaks (RAM stable)
- [ ] No stuttering or lag spikes
- [ ] Load time < 15 seconds

**Content:**
- [ ] 5+ missions available
- [ ] Multiple NPCs types working
- [ ] Shops and economy functional
- [ ] Police/Wanted system working

**Polish:**
- [ ] HUD displays clearly
- [ ] No missing textures/geometry
- [ ] Controls feel responsive
- [ ] Audio plays (when added)

---

## 📝 Test Report Template

```
Date: _______________
Tester: ______________
Build: v1.0.0
Hardware: _______________

Passed Tests: ___/10
Failed Tests: ___/10

Issues Found:
1. ___________________________
2. ___________________________
3. ___________________________

Notes:
________________________________

Status: [ ] PASS [ ] FAIL
```

---

## 🎯 Sign-Off Checklist

**Game is READY for 1.0 release when:**
- [ ] All 10 tests PASS
- [ ] No critical bugs found
- [ ] Performance meets targets
- [ ] Documentation complete
- [ ] Asset pipeline working
- [ ] Save system reliable

**Sign-off:**
- [ ] Developer: __________ Date: ______
- [ ] Tester: __________ Date: ______

---

**Last Updated:** April 18, 2026  
**Version:** 1.0  
**Status:** Ready for Testing
