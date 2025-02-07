import json

class SaveLoad:
    def __init__(self, player):
        self.player = player

    def save_game(self, slot=1):
        data = {
            "money": self.player.money,
            "position": (self.player.rect.x, self.player.rect.y)
        }
        with open(f"savegame_{slot}.json", "w") as file:
            json.dump(data, file)

    def load_game(self, slot=1):
        try:
            with open(f"savegame_{slot}.json", "r") as file:
                data = json.load(file)
                self.player.money = data["money"]
                self.player.rect.x, self.player.rect.y = data["position"]
        except FileNotFoundError:
            pass
