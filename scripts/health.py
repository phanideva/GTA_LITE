import pygame

class Health:
    def __init__(self, max_health):
        self.max_health = max_health
        self.current_health = max_health

    def take_damage(self, amount):
        self.current_health -= amount
        if self.current_health < 0:
            self.current_health = 0

    def draw(self, screen):
        pygame.draw.rect(screen, (255, 0, 0), (20, 50, 100, 10))
        pygame.draw.rect(screen, (0, 255, 0), (20, 50, (self.current_health / self.max_health) * 100, 10))
