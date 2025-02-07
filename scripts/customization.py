import pygame

class Customization:
    def __init__(self):
        self.outfits = ["Blue", "Red", "Green", "Black"]
        self.current_outfit = "Blue"

    def change_outfit(self, outfit):
        if outfit in self.outfits:
            self.current_outfit = outfit

    def draw(self, screen):
        font = pygame.font.Font(None, 30)
        text = font.render(f"Outfit: {self.current_outfit}", True, (255, 255, 255))
        screen.blit(text, (20, 50))
