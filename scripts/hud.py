import pygame

class HUD:
    def __init__(self, font):
        self.font = font

    def draw(self, screen, health, money):
        health_text = self.font.render(f"Health: {health}", True, (255, 0, 0))
        money_text = self.font.render(f"Money: ${money}", True, (0, 255, 0))
        screen.blit(health_text, (20, 70))
        screen.blit(money_text, (20, 90))
