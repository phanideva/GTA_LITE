import pygame
from settings import SCREEN_WIDTH, SCREEN_HEIGHT, FPS
from player import Player
from vehicle import Vehicle
from pedestrian import Pedestrian
from bullet import Bullet
from map import draw_map
from police_ai import Police
from gang_ai import Gangster
from traffic_ai import Traffic
from weapon import Weapon
from health import Health
from hud import HUD
from minimap import MiniMap
from weather import Weather
from shop import Shop
from economy import Economy
from bank import Bank
from customization import Customization
from save_load import SaveLoad
from multiplayer import Multiplayer

pygame.init()
screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT), pygame.FULLSCREEN)
clock = pygame.time.Clock()
font = pygame.font.Font(None, 30)

# Initialize game components
player = Player(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2)
car = Vehicle(SCREEN_WIDTH // 2 - 50, SCREEN_HEIGHT // 2 + 50)
pedestrians = [Pedestrian(200, 300), Pedestrian(500, 350)]
bullets = []
police = Police(100, 100)
gangsters = [Gangster(400, 300), Gangster(600, 400)]
traffic_cars = [Traffic(250, 100), Traffic(500, 200)]
weapon = Weapon()
health = Health(100)
hud = HUD(font)
minimap = MiniMap()
weather = Weather()
shop = Shop()
economy = Economy()
bank = Bank(300, 300)
customization = Customization()
save_load = SaveLoad(player)
multiplayer = Multiplayer()

running = True
while running:
    screen.fill((0, 0, 0))
    draw_map(screen)
    weather.update()
    weather.draw(screen)

    keys = pygame.key.get_pressed()
    player.move(keys)
    car.drive(keys)
    police.update(player)
    
    for gangster in gangsters:
        gangster.move()
        gangster.draw(screen)
    
    for traffic in traffic_cars:
        traffic.move()
        traffic.draw(screen)
    
    for bullet in bullets:
        bullet.move()
        bullet.draw(screen)
    
    for ped in pedestrians:
        ped.move()
        ped.draw(screen)
    
    if keys[pygame.K_SPACE]:  # Shoot
        if weapon.shoot():
            bullets.append(Bullet(player.rect.x + 20, player.rect.y + 10))
    
    if keys[pygame.K_1]:
        weapon.switch_weapon("Pistol")
    if keys[pygame.K_2]:
        weapon.switch_weapon("Rifle")
    if keys[pygame.K_3]:
        weapon.switch_weapon("Shotgun")

    if keys[pygame.K_r]:  # Reload
        weapon.reload()
    
    if keys[pygame.K_g]:  # Rob Bank
        if bank.rob_bank(player):
            police.commit_crime()
    
    if keys[pygame.K_c]:  # Change Outfit
        customization.change_outfit("Red")
    
    if keys[pygame.K_F5]:  # Save Game
        save_load.save_game()
    
    if keys[pygame.K_F9]:  # Load Game
        save_load.load_game()
    
    player.draw(screen)
    car.draw(screen)
    police.draw(screen)
    bank.draw(screen)
    weapon.draw(screen)
    health.draw(screen)
    hud.draw(screen, health.current_health, economy.money)
    minimap.draw(screen)
    shop.draw(screen, font)
    customization.draw(screen)

    pygame.display.flip()
    clock.tick(FPS)

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False

pygame.quit()
