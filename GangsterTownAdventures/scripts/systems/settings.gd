extends Node

# Game Settings and Constants

const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080
const FPS = 60

# Player Settings
const PLAYER_SPEED = 15.0
const PLAYER_SPRINT_SPEED = 25.0
const PLAYER_HEALTH = 100
const PLAYER_JUMP_FORCE = 20.0

# Vehicle Settings
const VEHICLE_SPEED = 30.0
const VEHICLE_MAX_SPEED = 50.0
const VEHICLE_ACCELERATION = 2.0
const VEHICLE_BRAKE_FORCE = 3.0

# AI Settings
const PEDESTRIAN_SPEED = 8.0
const TRAFFIC_SPEED = 15.0
const POLICE_SPEED = 20.0
const POLICE_DETECT_RANGE = 100.0
const GANG_SPEED = 18.0
const GANG_DETECT_RANGE = 80.0

# Weapon Settings
const BULLET_SPEED = 100.0
const BULLET_DAMAGE = 10
const WEAPON_FIRE_RATE = 0.2

# World Settings
const WORLD_SIZE = Vector3(500, 100, 500)
const GRAVITY = -9.8
const AIR_FRICTION = 0.1

# Money Settings
const MISSION_REWARD = 500
const VEHICLE_STEAL_REWARD = 1000
const NPC_KILL_REWARD = 100
