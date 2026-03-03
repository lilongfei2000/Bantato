extends "res://ui/menus/shop/shop_items_container.gd"

signal bantato_shop_item_banned(shop_item)

onready var BantatoService = get_node("/root/ModLoader/LoongFly-Bantato/BantatoService")


func connect_shop_items() -> void:
	.connect_shop_items()
	# Connect Bantato ban signals for all shop items
	for shop_item in _shop_items:
		var _error_ban = shop_item.connect("bantato_ban_button_pressed", self, "bantato_on_ban_button_pressed")


func bantato_on_ban_button_pressed(shop_item: ShopItem) -> void:
	"""Handle Bantato ban button press."""
	if _is_delay_active:
		return

	# Check if the player has enough gold to ban the item
	if RunData.get_player_gold(player_index) < shop_item.bantato_ban_value:
		emit_signal("shop_item_insufficient_currency", shop_item)
		return

	BantatoService.ban(shop_item, player_index)

	emit_signal("bantato_shop_item_banned", shop_item)

	# Deactivate the item in the shop
	for item in _shop_items:
		if item.item_data and item.item_data.my_id == shop_item.item_data.my_id:
			item.deactivate()

	update_buttons_color()

	_is_delay_active = true
	_buy_delay_timer.start() # We can make use of it for us, too
	