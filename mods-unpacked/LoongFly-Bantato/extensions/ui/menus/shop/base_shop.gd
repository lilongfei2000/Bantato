extends "res://ui/menus/shop/base_shop.gd"


func _ready()->void :
	var player_count: int = RunData.get_player_count()
	for player_index in player_count:
		var shop_items_container = _get_shop_items_container(player_index)
		var _error_connect = shop_items_container.connect("shop_item_banned", self, "on_shop_item_banned", [player_index])
		var banned_items = RunData.get_player_banned_items(player_index)
		var player_gear_container = _get_gear_container(player_index)
		player_gear_container.set_banned_data(banned_items)
		var banned_items_container = player_gear_container.banned_items_container
		_error_connect = banned_items_container._elements.connect("focus_lost", self, "_on_player_focus_lost", [player_index])
		_popup_manager.connect_banned_inventory_container(banned_items_container)

	var _error_connect = _popup_manager.connect("banned_element_focused", self, "_on_banned_element_focused")


func on_shop_item_banned(shop_item: ShopItem, player_index: int)->void : 
	for item in _shop_items[player_index]:
		if item[0].my_id and item[0].my_id == shop_item.item_data.my_id:
			_shop_items[player_index].erase(item)

	RunData.remove_currency(shop_item.ban_value, player_index)
	ban_item(shop_item.item_data, player_index)
	_get_shop_items_container(player_index).reload_shop_items()


func ban_item(item_data: ItemParentData, player_index: int) -> void :
	RunData.ban_item(item_data, player_index)

	var player_gear_container = _get_gear_container(player_index)
	player_gear_container.banned_items_container._elements.add_element(item_data)


func _on_banned_element_focused(_element: InventoryElement, _player_index: int) -> void :
	pass
