import pygame

class MiniMap:
    def __init__(self):
        self.rect = pygame.Rect(600, 20, 150, 150)  # Mini-map square

    def draw(self, screen):
        pygame.draw.rect(screen, (200, 200, 200), self.rect)
