import pygame

class Combat:
    def __init__(self):
        self.punch_damage = 5

    def punch(self, target):
        target.take_damage(self.punch_damage)

    def draw(self, screen, player):
        punch_text = pygame.font.Font(None, 30).render("Press F to Punch", True, (255, 255, 255))
        screen.blit(punch_text, (player.rect.x - 20, player.rect.y - 20))
