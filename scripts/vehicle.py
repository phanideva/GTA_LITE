import pygame
from settings import CAR_SPEED, CAR_COLOR

class Vehicle:
    def __init__(self, x, y):
        self.rect = pygame.Rect(x, y, 50, 30)
        self.speed = CAR_SPEED
        self.driving = False
        self.color = CAR_COLOR

    def enter_vehicle(self, player):
        """Attach player to car"""
        self.driving = True
        player.rect.x = self.rect.x
        player.rect.y = self.rect.y

    def exit_vehicle(self, player):
        """Detach player from car"""
        self.driving = False
        player.rect.x = self.rect.x + 50
        player.rect.y = self.rect.y

    def drive(self, keys):
        if self.driving:
            if keys[pygame.K_w]:
                self.rect.y -= self.speed
            if keys[pygame.K_s]:
                self.rect.y += self.speed
            if keys[pygame.K_a]:
                self.rect.x -= self.speed
            if keys[pygame.K_d]:
                self.rect.x += self.speed

    def draw(self, screen):
        pygame.draw.rect(screen, self.color, self.rect)
