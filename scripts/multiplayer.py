import pygame
from player import Player

class Multiplayer:
    def __init__(self):
        self.player1 = Player(400, 300, "assets/characters/player.png")
        self.player2 = Player(450, 300, "assets/characters/player2.png")

    def update(self, keys):
        self.player1.move(keys)
        self.player2.move(keys)

    def draw(self, screen):
        self.player1.draw(screen)
        self.player2.draw(screen)
