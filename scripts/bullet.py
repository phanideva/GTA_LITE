import pygame

class Bullet:
    def __init__(self, x, y, color=(255, 255, 0)):  # Yellow bullet
        self.rect = pygame.Rect(x, y, 10, 5)
        self.speed = 10
        self.color = color

    def move(self):
        self.rect.x += self.speed  # Moves forward

    def draw(self, screen):
        pygame.draw.rect(screen, self.color, self.rect)
