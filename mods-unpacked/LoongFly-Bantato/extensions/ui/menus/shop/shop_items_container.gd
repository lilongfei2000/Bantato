extends "res://ui/menus/shop/shop_items_container.gd"


signal shop_item_banned(shop_item)


func connect_shop_items()->void :
	.connect_shop_items()
	for shop_item in _shop_items:
		var _error_ban = shop_item.connect("ban_button_pressed", self, "on_shop_item_ban_button_pressed")


func on_shop_item_ban_button_pressed(shop_item: ShopItem)->void :
	if _is_delay_active:
		return
	# Check if the player has enough gold to ban the item
	if RunData.get_player_currency(player_index) < shop_item.ban_value:
		emit_signal("shop_item_insufficient_currency", shop_item)
		return
		
	emit_signal("shop_item_banned", shop_item)
	
	# Deactivate the item in the shop
	for item in _shop_items:
		if item.item_data and item.item_data.my_id == shop_item.item_data.my_id:
			item.deactivate()
	
	update_buttons_color()
	
	_is_delay_active = true
	_buy_delay_timer.start()
