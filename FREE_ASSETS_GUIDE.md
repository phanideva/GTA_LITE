# GTA Advanced 3D - Free Assets Download Guide

## Overview
This guide lists recommended FREE (CC0 / CC-BY) asset sources for the 3D GTA game.

## 1. Realistic Character Models (Mixamo)

Since the procedural characters in `character_model.gd` are blocky, you can replace them with AAA-quality characters using Adobe Mixamo (it's completely free).

**Steps to Import Characters:**
1. Go to [mixamo.com](https://www.mixamo.com/).
2. Create an Adobe account or log in.
3. Browse the **Characters** tab. Recommended realistic characters:
   - *Remy* or *Kachin* (for the main player, Leo)
   - *Vanguard* or *SWAT* (for Police/Enforcers)
   - *Streetwear* characters (for Pedestrians and Syndicate members)
4. Click **Download** and select **Format: FBX (.fbx)** and **Pose: T-Pose**.
5. Move the downloaded `.fbx` files into your Godot project under `assets/models/characters/`.
6. In Godot, double-click the imported `.fbx`, go to the **Import** tab, and generate the Rig/Bones.
7. Open `player.tscn` or `pedestrian.tscn`, delete the old `PlayerModel` (the script-generated one), and drag your new Mixamo scene into the player tree.

## 2. Realistic Vehicles (Sketchfab)

You can download high-poly cars from Sketchfab to replace the script-generated primitives. The `vehicle.gd` script relies on four wheels to spin.

**Steps to Import Cars:**
1. Go to [sketchfab.com](https://sketchfab.com/).
2. Search for "Downloadable Car" or "Sedan" and check the **Downloadable** filter. Look for low-to-mid poly realistic cars (ensure they are CC-Attribution free).
3. Download the GLTF/GLB format.
4. Move the files to `assets/models/vehicles/`.
5. Open `vehicle.tscn`. Delete the procedural meshes inside `_build_car_model()` or simply drag your new car GLB into the scene.
6. Make sure the car object has 4 child nodes for tires (e.g., `Wheel_FL`, `Wheel_FR`, `Wheel_BL`, `Wheel_BR`). Update `wheel_nodes = [$Wheel_FL, $Wheel_FR, ...]` in `vehicle.gd` so the script can spin them automatically.

## 3. City Map & Environment

Instead of generating block buildings, download a pre-built realistic city pack.

**Steps to Import the City:**
1. Search Sketchfab or the Unity Asset Store (using an FBX converter) for "Free City Block" or "City Environment".
2. Download the GLTF/GLB files and place them in `assets/models/world/`.
3. Drag the city models into `main.tscn`.
4. **CRITICAL:** Select the city mesh in the Godot editor, click the **Mesh** menu at the top of the 3D viewport, and select **Create Trimesh Static Body**. This automatically generates the floor/wall collisions so the Player and NPCs don't fall through the map!

## 4. Audio (FreeSound)

For the GTA-style intro music, gunshots, and radio.

**Steps to Import Audio:**
1. Go to [freesound.org](https://freesound.org/).
2. Search for "Hip Hop Beat" or "Action Music".
3. Download the `.wav` or `.ogg` files.
4. Place them in `assets/audio/`.
5. Open `main_menu.tscn` and add an `AudioStreamPlayer`. Assign your new music file to the `Stream` property and check the `Autoplay` box.

## 5. Final Configuration

To ensure your game bundles correctly:
1. Go to **Project > Export** in Godot.
2. Add a preset (Windows Desktop, macOS, or Linux).
3. Under the **Resources** tab, make sure `Filters to export non-resource files/folders` includes `*.fbx, *.glb, *.wav, *.mp3, *.ogg`.
4. Click **Export Project** to generate the final playable `.exe` or `.app` bundle.

### 1. Sketchfab (https://sketchfab.com)
**Best For:** High-quality 3D models
- Free filter available
- License: CC0, CC-BY
- Formats: `.glb`, `.gltf`, `.fbx`, `.obj`
- Examples:
  - Search: "free low poly car"
  - Search: "free 3d character"
  - Search: "free building model"

### 2. OpenGameArt (https://opengameart.org)
**Best For:** Game-ready assets
- All assets are free
- Focused on game development
- Formats: `.blend`, `.fbx`, `.obj`, `.dae`
- Examples:
  - Search: "character models"
  - Search: "vehicle"
  - Search: "weapons"

### 3. Kenney.nl (https://kenney.nl)
**Best For:** Stylized, consistent assets
- CC0 license (public domain)
- Art pack bundles
- Formats: `.blend`, `.obj`, `.fbx`
- Popular packs:
  - "3D Characters"
  - "3D Vehicles"
  - "3D Models - Furniture"

### 4. Poly Haven (https://polyhaven.com)
**Best For:** Textures and HDR
- CC0 license
- High-quality PBR textures
- Formats: `.exr`, `.hdr`, `.png`, `.jpg`

### 5. TurboSquid Free (https://www.turbosquid.com/search/3d-models/free)
**Best For:** Professional quality
- Free tier available
- License verified
- Formats: `.max`, `.obj`, `.fbx`, `.blend`

### 6. CGTrader (https://www.cgtrader.com/free-3d-models)
**Best For:** Variety of models
- Free section available
- Professional creators
- Formats: Various

---

## 📋 Recommended Asset List

### Player Character
```
1. Sketchfab: "Free Low Poly Man"
   URL: https://sketchfab.com/search?q=free+low+poly+man&type=models&license=free
   
2. OpenGameArt: "Old Spy Guy"
   URL: https://opengameart.org/content/old-spy-guy
   
3. Kenney: "3D Character"
   URL: https://kenney.nl/assets
```

### Vehicles

#### Police Car
```
1. Sketchfab: "Free Police Car"
   URL: https://sketchfab.com/search?q=free+police+car
   
2. OpenGameArt: "Vehicles Pack"
   URL: https://opengameart.org/content/vehicles-pack
```

#### Civilian Cars
```
1. Kenney: "3D Vehicles"
   URL: https://kenney.nl/assets (search "vehicles")
   
2. Sketchfab: "Free Car Model Pack"
   URL: https://sketchfab.com/search?q=free+car+pack
```

### Buildings & Environment

#### City Buildings
```
1. Sketchfab: "Free Building Model"
   Search: "free low poly building"
   
2. OpenGameArt: "City Buildings"
   URL: https://opengameart.org/search/type:art/models
```

#### Trees & Nature
```
1. Sketchfab: "Free Tree Pack"
   Search: "free tree low poly"
   
2. Kenney: "Nature Pack"
   URL: https://kenney.nl/assets
```

### Weapons

#### Guns
```
1. Sketchfab: "Free Weapon Pack"
   Search: "free pistol rifle shotgun"
   
2. OpenGameArt: "Weapons Pack"
   URL: https://opengameart.org/search/type:art/weapons
```

### UI & Props

```
1. Kenney: "UI Pack"
   URL: https://kenney.nl/assets
   
2. OpenGameArt: "UI Elements"
   URL: https://opengameart.org/search/type:art/ui-elements
```

---

## 🎵 Audio Assets

### Sound Effects (SFX)

#### Gun Sounds
```
Website: Freesound.org
Search: "gunshot sound effect"
License: CC-BY or CC0
Formats: `.wav`, `.mp3`, `.ogg`

Top SFX:
- Gunshot
- Rifle shot
- Shell casing
- Impact sounds
```

#### Vehicle Sounds
```
Website: Freesound.org
Search: "car engine sound"

Top SFX:
- Car engine
- Tire screech
- Car crash
- Door slam
```

#### UI Sounds
```
Website: Freesound.org
Search: "notification beep"

Top SFX:
- Button click
- Notification
- Ping
- Success sound
```

### Music

#### Background Music
```
Website: Incompetech (https://incompetech.com)
License: CC-BY
- Epic action music
- Ambient background
- Driving music
```

#### Alternative Sources
```
1. FreeMusicArchive (https://freemusicarchive.org)
2. Freesound.org (search "background music")
3. YouTube Audio Library (free, no account needed)
```

---

## 📥 How to Download & Import

### Step 1: Download
1. Visit website (e.g., Sketchfab)
2. Find asset you like
3. Click "Download"
4. Check license is CC0 or CC-BY
5. Download appropriate format

### Step 2: Organize Files
```
Create folders in godot_project/assets/:
- models/          (3D models: .glb, .gltf, .fbx)
- textures/        (Images: .png, .jpg, .hdr)
- audio/           (Sound: .ogg, .wav, .mp3)
```

### Step 3: Import to Godot
```gdscript
# In scripts, reference assets:
var player_model = preload("res://assets/models/character.glb")
var car_model = preload("res://assets/models/car.glb")
var gun_sound = preload("res://assets/audio/gunshot.ogg")

# Use in scenes:
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = player_model
```

---

## ⭐ Recommended Full Asset Packs

### Kenney Game Assets
- **Link:** https://kenney.nl/assets
- **License:** CC0
- **Best For:** Consistent, styled assets
- **Includes:** Characters, vehicles, buildings, UI
- **Download:** `.blend` files (can export to `.fbx`)

### OpenGameArt Collections
- **Link:** https://opengameart.org
- **License:** Various (all free/open)
- **Best For:** Game-ready models
- **Categories:** Characters, vehicles, props, audio

### Sketchfab Collections
- **Link:** https://sketchfab.com/search?q=free+game+assets
- **License:** Filter by CC0/CC-BY
- **Best For:** High-quality models
- **Formats:** `.glb`, `.gltf` (best for Godot)

---

## 🎨 Asset Formats Support

### Godot 4 Supports

#### 3D Models
- ✅ `.glb` (best choice - includes textures)
- ✅ `.gltf` (good choice)
- ✅ `.fbx` (supported)
- ✅ `.dae` (Collada)
- ✅ `.obj` (simple geometry)

#### Textures
- ✅ `.png` (best for lossless)
- ✅ `.jpg` (good for photos)
- ✅ `.hdr` (for lighting)
- ✅ `.exr` (high-quality)

#### Audio
- ✅ `.ogg` (recommended - compressed)
- ✅ `.mp3` (supported)
- ✅ `.wav` (uncompressed)

---

## 🔗 Quick Download Links

### Characters
1. https://sketchfab.com/search?q=free+3d+character&license=free
2. https://opengameart.org/search/type:art/characters

### Vehicles
1. https://sketchfab.com/search?q=free+car&license=free
2. https://kenney.nl/assets/3d-vehicles

### Buildings
1. https://sketchfab.com/search?q=free+building&license=free
2. https://opengameart.org/search/type:art/buildings

### Weapons
1. https://sketchfab.com/search?q=free+weapon&license=free
2. https://opengameart.org/search/type:art/weapons

### Audio (SFX)
1. https://freesound.org/search/?q=gunshot&f=license:%22Creative%20Commons%200%20(public%20domain)%22
2. https://freesound.org/search/?q=car+engine

### Music
1. https://incompetech.com/
2. https://freemusicarchive.org/music/curator/Ambient

---

## ⚖️ License Check

**Before using an asset, verify:**

✅ **CC0** - Public domain (use freely, no attribution)
✅ **CC-BY** - Attribution required (give credit)
❌ **CC-BY-SA** - Attribution + Share-alike (check requirements)
❌ **CC-BY-NC** - Non-commercial only
❌ **All rights reserved** - Contact creator

**Most reliable sources:**
- Kenney.nl (CC0 everything)
- Sketchfab (filter by CC0/CC-BY)
- OpenGameArt.org (verified free)

---

## 💡 Pro Tips

1. **Start with Kenney.nl** - Consistent, CC0, game-ready
2. **Use `.glb` format** - Includes textures, best for Godot
3. **Check scale** - Models may need scaling in Godot
4. **Test before using** - Import a few to check quality
5. **Keep organized** - Sort by type (models, textures, audio)
6. **Backup licenses** - Save license info with assets

---

## Asset Pipeline Workflow

```
1. Browse website → Find model
2. Download `.glb` file
3. Place in godot_project/assets/models/
4. Godot auto-imports
5. Drag into scene or reference in script
6. Test in game
7. Adjust materials/colors if needed
8. Deploy!
```

---

**Last Updated:** April 18, 2026  
**Version:** 1.0  
**All sources verified for free use**
