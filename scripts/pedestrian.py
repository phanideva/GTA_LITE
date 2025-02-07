import pygame
import random
from settings import PEDESTRIAN_SPEED

class Pedestrian:
    def __init__(self, x, y, color=(0, 255, 0)):  # Green pedestrian
        self.rect = pygame.Rect(x, y, 20, 20)
        self.speed = PEDESTRIAN_SPEED
        self.direction = random.choice(["left", "right"])
        self.color = color

    def move(self):
        if self.direction == "left":
            self.rect.x -= self.speed
            if self.rect.x < 0:
                self.direction = "right"
        else:
            self.rect.x += self.speed
            if self.rect.x > 800:
                self.direction = "left"

    def draw(self, screen):
        pygame.draw.ellipse(screen, self.color, self.rect)  # Circle shape
