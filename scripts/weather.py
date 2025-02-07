import pygame
import random

class Weather:
    def __init__(self):
        self.time_of_day = "Day"  # Can be "Day" or "Night"
        self.weather = "Clear"  # Options: "Clear", "Rain", "Fog"

    def update(self):
        if random.randint(1, 500) == 1:  # Change randomly
            self.time_of_day = "Night" if self.time_of_day == "Day" else "Day"
        if random.randint(1, 800) == 1:
            self.weather = random.choice(["Clear", "Rain", "Fog"])

    def draw(self, screen):
        if self.time_of_day == "Night":
            overlay = pygame.Surface((800, 600))
            overlay.set_alpha(100)
            overlay.fill((0, 0, 50))
            screen.blit(overlay, (0, 0))
