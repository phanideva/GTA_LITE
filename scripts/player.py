import pygame
from settings import PLAYER_SPEED

class Player:
    def __init__(self, x, y, color=(0, 0, 255)):  # Blue color
        self.rect = pygame.Rect(x, y, 30, 30)  # Square shape
        self.speed = PLAYER_SPEED
        self.color = color

    def move(self, keys):
        if keys[pygame.K_w]:  # Move Up
            self.rect.y -= self.speed
        if keys[pygame.K_s]:  # Move Down
            self.rect.y += self.speed
        if keys[pygame.K_a]:  # Move Left
            self.rect.x -= self.speed
        if keys[pygame.K_d]:  # Move Right
            self.rect.x += self.speed

    def draw(self, screen):
        pygame.draw.rect(screen, self.color, self.rect)  # Draw rectangle
