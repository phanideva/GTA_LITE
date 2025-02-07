import pygame
import random

class Traffic:
    def __init__(self, x, y):
        self.rect = pygame.Rect(x, y, 50, 30)  # Rectangle for cars
        self.speed = random.randint(2, 4)

    def move(self):
        self.rect.y += self.speed
        if self.rect.y > 600:
            self.rect.y = -50

    def draw(self, screen):
        pygame.draw.rect(screen, (150, 150, 150), self.rect)
