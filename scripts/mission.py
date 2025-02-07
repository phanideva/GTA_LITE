import pygame

class Mission:
    def __init__(self):
        self.active = False
        self.description = "Steal the car and escape!"
        self.completed = False

    def start(self):
        self.active = True

    def check_completion(self, player):
        if player.rect.x > 600:  # Example: If the player reaches a safe zone
            self.completed = True
            self.active = False
            return True
        return False

    def draw(self, screen, font):
        if self.active:
            mission_text = font.render(f"Mission: {self.description}", True, (255, 255, 0))
            screen.blit(mission_text, (20, 20))
