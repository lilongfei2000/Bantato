extends "res://ui/menus/shop/player_gear_container.gd"

# Access BantatoService
onready var BantatoService = get_node("/root/ModLoader/Longfei-Bantato/BantatoService")
onready var bantato_banned_items_container: InventoryContainer = BantatoService.setup_banned_items_container(items_container)

var _bantato_item_index: Dictionary


func bantato_set_banned_data(banned_data: Dictionary) -> void:
	"""Set the Bantato-banned items data."""
	BantatoService.set_banned_data(bantato_banned_items_container, banned_data)

	_bantato_item_index = {}
	for id in banned_data.keys():
		_bantato_item_index[id] = _bantato_item_index.size()


func bantato_add_to_banned_container(item: ItemParentData) -> void:
	"""Add an item to the Bantato banned items container."""
	if _bantato_item_index.has(item.my_id):
		var banned_items = bantato_banned_items_container._elements.get_children()
		var index = _bantato_item_index[item.my_id]
		banned_items[index].add_to_number()
	else:
		_bantato_item_index[item.my_id] = _bantato_item_index.size()
		if item.is_cursed:
			item = BantatoService.get_item_by_id(item.my_id)
		bantato_banned_items_container._elements.add_element(item, false, false)
