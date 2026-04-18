extends Node
# Economy System Script
# Handles money, shops, bank, and transactions

var bank_balance: int = 0
var inventory: Dictionary = {}
var shops: Array = []

func _ready():
	add_to_group("economy")
	setup_shops()

func setup_shops():
	shops = [
		{
			"name": "Weapons Shop",
			"items": [
				{"name": "Pistol", "price": 500},
				{"name": "Rifle", "price": 1500},
				{"name": "Shotgun", "price": 2000},
			]
		},
		{
			"name": "Clothing Store",
			"items": [
				{"name": "Black Suit", "price": 300},
				{"name": "Sports Outfit", "price": 200},
				{"name": "Casual Wear", "price": 150},
			]
		},
		{
			"name": "Vehicle Tuning",
			"items": [
				{"name": "Nitro Boost", "price": 5000},
				{"name": "Performance Engine", "price": 8000},
				{"name": "Custom Paint", "price": 2000},
			]
		}
	]

func add_money(amount: int):
	Globals.add_money(amount)

func remove_money(amount: int) -> bool:
	if Globals.player_money >= amount:
		Globals.player_money -= amount
		return true
	return false

func buy_item(shop_name: String, item_name: String) -> bool:
	for shop in shops:
		if shop["name"] == shop_name:
			for item in shop["items"]:
				if item["name"] == item_name:
					if remove_money(item["price"]):
						add_to_inventory(item_name)
						print("Purchased: ", item_name)
						return true
	return false

func deposit_to_bank(amount: int) -> bool:
	if remove_money(amount):
		bank_balance += amount
		print("Deposited: $", amount)
		return true
	return false

func withdraw_from_bank(amount: int) -> bool:
	if bank_balance >= amount:
		bank_balance -= amount
		Globals.player_money += amount
		print("Withdrew: $", amount)
		return true
	return false

func add_to_inventory(item_name: String):
	if item_name in inventory:
		inventory[item_name] += 1
	else:
		inventory[item_name] = 1

func remove_from_inventory(item_name: String) -> bool:
	if item_name in inventory and inventory[item_name] > 0:
		inventory[item_name] -= 1
		return true
	return false

func get_inventory() -> Dictionary:
	return inventory

func get_player_net_worth() -> int:
	return Globals.player_money + bank_balance
