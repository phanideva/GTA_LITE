import pygame
from economy import Economy

class Shop:
    def __init__(self):
        self.items = {"Pistol": 50, "Rifle": 150, "Health Pack": 30}
        self.economy = Economy()

    def buy(self, item):
        if item in self.items:
            return self.economy.spend_money(self.items[item])
        return False

    def draw(self, screen, font):
        y_offset = 100
        for item, price in self.items.items():
            text = font.render(f"{item}: ${price}", True, (255, 255, 255))
            screen.blit(text, (50, y_offset))
            y_offset += 30
