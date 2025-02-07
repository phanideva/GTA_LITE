import pygame

def draw_map(screen):
    screen.fill((50, 150, 50))  # Green ground
    pygame.draw.rect(screen, (100, 100, 100), (100, 100, 600, 400))  # Grey road
    pygame.draw.rect(screen, (50, 50, 50), (120, 100, 560, 30))  # Road lines
    pygame.draw.rect(screen, (50, 50, 50), (120, 470, 560, 30))  # Road lines
    pygame.draw.rect(screen, (200, 200, 200), (600, 200, 80, 80))  # Building
