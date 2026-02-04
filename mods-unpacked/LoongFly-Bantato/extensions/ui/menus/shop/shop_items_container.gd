extends "res://ui/menus/shop/shop_items_container.gd"


func connect_shop_items() -> void:
	.connect_shop_items()
	# Connect Bantato ban signals for all shop items
	for shop_item in _shop_items:
		if shop_item.has_signal("bantato_ban_button_pressed"):
			var _error_ban = shop_item.connect("bantato_ban_button_pressed", self, "on_bantato_ban_button_pressed")


func on_bantato_ban_button_pressed(shop_item: ShopItem) -> void:
	"""Handle Bantato ban button press."""
	if _is_delay_active:
		return

	# Check if the player has enough gold to ban the item
	if RunData.get_player_currency(player_index) < shop_item.bantato_ban_value:
		emit_signal("shop_item_insufficient_currency", shop_item)
		return

	# Signal to base_shop that item was banned
	if _base_shop_ref and _base_shop_ref.has_method("on_shop_item_banned"):
		_base_shop_ref.on_shop_item_banned(shop_item, player_index)

	# Deactivate the item in the shop
	for item in _shop_items:
		if item.item_data and item.item_data.my_id == shop_item.item_data.my_id:
			item.deactivate()

	update_buttons_color()

	_is_delay_active = true
	_buy_delay_timer.start()