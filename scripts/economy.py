class Economy:
    def __init__(self):
        self.money = 100

    def earn_money(self, amount):
        self.money += amount

    def spend_money(self, amount):
        if self.money >= amount:
            self.money -= amount
            return True
        return False
