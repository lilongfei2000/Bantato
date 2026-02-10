extends "res://ui/menus/shop/player_gear_container.gd"

# Access BantatoService
onready var BantatoService = get_node("/root/ModLoader/LoongFly-Bantato/BantatoService")

# Translation keys for UI strings
const BANTATO_STR_BANNED_ITEMS = "BANTATO_BANNED_ITEMS"
const BANTATO_STR_SWITCH_TO_BANNED = "BANTATO_SWITCH_TO_BANNED"
const BANTATO_STR_SWITCH_TO_ITEMS = "BANTATO_SWITCH_TO_ITEMS"

var bantato_banned_items_container: InventoryContainer
var _bantato_button_on_banned_container
var _bantato_button_on_items_container

onready var _bantato_item_index: Dictionary = {}


func _ready() -> void:
	# Setup Bantato banned items container
	bantato_setup_banned_items_container()
	_bantato_button_on_items_container = bantato_add_button(items_container)
	_button_on_items_container.text = BANTATO_STR_SWITCH_TO_BANNED
	_button_on_items_container.connect("pressed", self, "_bantato_switch_container_display")

	_bantato_button_on_banned_container = bantato_add_button(bantato_banned_items_container)
	_bantato_button_on_banned_container.text = BANTATO_STR_SWITCH_TO_ITEMS
	_button_on_banned_items_container.connect("pressed", self, "_bantato_switch_container_display")


func bantato_setup_banned_items_container() -> void:
	"""Create a separate container for Bantato-banned items."""
	if RunData.is_coop_run:
		bantato_banned_items_container = load("res://ui/menus/shop/coop_inventory_container.tscn").instance()
		items_container.add_constant_override("separation", 10)
		bantato_banned_items_container.add_constant_override("separation", 10)
		weapons_container.add_constant_override("separation", 10)
		bantato_banned_items_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		bantato_banned_items_container = load("res://ui/menus/shop/inventory_container.tscn").instance()

	bantato_banned_items_container.visible = false
	bantato_banned_items_container.reserve_column_count = items_container.reserve_column_count
	bantato_banned_items_container.reserve_row_count = items_container.reserve_row_count
	bantato_banned_items_container.rect_size = items_container.rect_size

	add_child(bantato_banned_items_container)
	move_child(bantato_banned_items_container, items_container.get_index())
	

func bantato_add_button(container: InventoryContainer) -> Node:
	"""Add a toggle button to a container."""
	var toggle_button = MyMenuButton.new()
	if RunData.is_coop_run:
		toggle_button.add_font_override("font", preload("res://resources/fonts/actual/base/font_26.tres"))
	else:
		toggle_button.add_font_override("font", preload("res://resources/fonts/actual/base/font_26.tres"))
	toggle_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	container.remove_child(container._label)
	# Create HBoxContainer to hold Label and Button
	var hbox = HBoxContainer.new()
	# Add spacer for flexible layout
	hbox.add_child(toggle_button)
	hbox.add_child(container._label)
	container._label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	container.add_child(hbox)
	container.move_child(hbox, 0)

	return toggle_button


func bantato_set_banned_data(banned_data: Array) -> void:
	"""Set the Bantato-banned items data."""
	_bantato_item_index = {}
	bantato_banned_items_container._label.text = BANTATO_STR_BANNED_ITEMS
	for banned_item_data in banned_data:
		var item_data = banned_item_data[0]
		var prevent_count = banned_item_data[1]
		bantato_banned_items_container._elements.add_element_with_count(item_data, prevent_count, false, 0.5)
		_bantato_item_index[item_data.my_id] = _bantato_item_index.size()


func bantato_add_to_banned_container(item: ItemParentData) -> void:
	"""Add an item to the Bantato banned items container."""
	if _bantato_item_index.has(item.my_id):
		var banned_items = bantato_banned_items_container._elements.get_children()
		var index = _bantato_item_index[item.my_id]
		banned_items[index].add_to_number()
	else:
		bantato_banned_items_container._elements.add_element(item, false, false)
		_bantato_item_index[item.my_id] = _bantato_item_index.size()


func _bantato_switch_container_display() -> void:
	"""Toggle visibility of Bantato banned items container."""
	if items_container.visible:
		items_container.visible = false
		bantato_banned_items_container.visible = true
		_bantato_button_on_banned_container.grab_focus()
	else:
		bantato_banned_items_container.visible = false
		items_container.visible = true
		_bantato_button_on_items_container.grab_focus()
