extends "res://ui/menus/shop/base_shop.gd"

# Access BantatoService
onready var BantatoService = get_node("/root/ModLoader/LoongFly-Bantato/BantatoService")

func _ready() -> void:
	# Connect to Bantato ban events for each player
	var player_count: int = RunData.get_player_count()
	for player_index in player_count:
		var shop_items_container = _get_shop_items_container(player_index)

		# Note: Bantato ban handling will be done through a different signal
		# We'll need to extend shop_items_container.gd to handle this

		# Setup banned items display
		var banned_items = BantatoService.get_banned_items(player_index) if BantatoService else []
		var player_gear_container = _get_gear_container(player_index)

		if player_gear_container.has_method("set_bantato_banned_data"):
			player_gear_container.set_bantato_banned_data(banned_items)

		var banned_items_container = player_gear_container.bantato_banned_items_container if player_gear_container.has_method("get_bantato_container") else null

		if banned_items_container:
			var _error_connect = banned_items_container._elements.connect("focus_lost", self, "_on_player_focus_lost", [player_index])

			if _popup_manager and _popup_manager.has_method("connect_bantato_banned_inventory_container"):
				_popup_manager.connect_bantato_banned_inventory_container(banned_items_container)


func on_shop_item_banned(shop_item: ShopItem, player_index: int) -> void:
	"""Handle when an item is banned via Bantato."""
	# Remove the item from current shop items
	for item in _shop_items[player_index]:
		if item[0].my_id and item[0].my_id == shop_item.item_data.my_id:
			_shop_items[player_index].erase(item)
			break

	# Reload the shop items container
	_get_shop_items_container(player_index).reload_shop_items()

	# Update the banned items display
	var player_gear_container = _get_gear_container(player_index)
	if player_gear_container.has_method("add_to_bantato_banned_container"):
		player_gear_container.add_to_bantato_banned_container(shop_item.item_data)


func _on_banned_element_focused(element: InventoryElement, player_index: int) -> void:
	"""Handle focus on banned item element."""
	._on_banned_element_focused(element, player_index)