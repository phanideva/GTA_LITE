import pygame

class Weapon:
    def __init__(self):
        self.weapons = {
            "Pistol": {"ammo": 10, "damage": 5},
            "Rifle": {"ammo": 30, "damage": 10},
            "Shotgun": {"ammo": 5, "damage": 15},
        }
        self.current_weapon = "Pistol"

    def switch_weapon(self, weapon_name):
        if weapon_name in self.weapons:
            self.current_weapon = weapon_name

    def shoot(self):
        if self.weapons[self.current_weapon]["ammo"] > 0:
            self.weapons[self.current_weapon]["ammo"] -= 1
            return True
        return False

    def reload(self):
        self.weapons[self.current_weapon]["ammo"] = 10

    def draw(self, screen):
        font = pygame.font.Font(None, 30)
        text = font.render(f"Weapon: {self.current_weapon} | Ammo: {self.weapons[self.current_weapon]['ammo']}", True, (255, 255, 255))
        screen.blit(text, (20, 20))
