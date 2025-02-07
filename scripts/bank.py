import pygame

class Bank:
    def __init__(self, x, y):
        self.rect = pygame.Rect(x, y, 100, 60)
        self.money_inside = 1000

    def rob_bank(self, player):
        if self.money_inside > 0:
            player.money += 200
            self.money_inside -= 200
            return True  # Crime committed
        return False

    def draw(self, screen):
        pygame.draw.rect(screen, (255, 215, 0), self.rect)
