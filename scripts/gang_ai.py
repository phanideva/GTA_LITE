import pygame
import random

class Gangster:
    def __init__(self, x, y):
        self.rect = pygame.Rect(x, y, 30, 30)  # Square gangster
        self.speed = 3
        self.direction = random.choice(["left", "right"])

    def move(self):
        if self.direction == "left":
            self.rect.x -= self.speed
            if self.rect.x < 100:
                self.direction = "right"
        else:
            self.rect.x += self.speed
            if self.rect.x > 700:
                self.direction = "left"

    def draw(self, screen):
        pygame.draw.rect(screen, (255, 0, 0), self.rect)
