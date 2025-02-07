import pygame

class Police:
    def __init__(self, x, y):
        self.rect = pygame.Rect(x, y, 40, 40)
        self.speed = 4
        self.wanted_level = 0

    def commit_crime(self):
        self.wanted_level += 1

    def update(self, player):
        if self.wanted_level > 0:
            self.chase(player)

    def chase(self, player):
        if self.rect.x < player.rect.x:
            self.rect.x += self.speed
        elif self.rect.x > player.rect.x:
            self.rect.x -= self.speed

        if self.rect.y < player.rect.y:
            self.rect.y += self.speed
        elif self.rect.y > player.rect.y:
            self.rect.y -= self.speed

    def draw(self, screen):
        pygame.draw.rect(screen, (0, 0, 255), self.rect)
