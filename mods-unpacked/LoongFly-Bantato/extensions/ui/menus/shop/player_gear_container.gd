extends "res://ui/menus/shop/player_gear_container.gd"

# Access BantatoService
onready var BantatoService = get_node("/root/ModLoader/LoongFly-Bantato/BantatoService")

var bantato_banned_items_container: InventoryContainer
var _button_on_bantato_banned_container
var bantato_display_visible := false


func _ready() -> void:
	# Setup Bantato banned items container
	setup_bantato_banned_items_container()


func setup_bantato_banned_items_container() -> void:
	"""Create a separate container for Bantato-banned items."""
	if RunData.is_coop_run:
		bantato_banned_items_container = load("res://ui/menus/shop/coop_inventory_container.tscn").instance()
	else:
		bantato_banned_items_container = load("res://ui/menus/shop/inventory_container.tscn").instance()

	bantato_banned_items_container.visible = false
	bantato_banned_items_container.reserve_column_count = items_container.reserve_column_count
	bantato_banned_items_container.reserve_row_count = items_container.reserve_row_count
	bantato_banned_items_container.rect_size = items_container.rect_size

	add_child(bantato_banned_items_container)
	move_child(bantato_banned_items_container, items_container.get_index())

	# Create toggle button
	_button_on_bantato_banned_container = add_button(bantato_banned_items_container)
	_button_on_bantato_banned_container.text = "SHOW_BANNED"  # Translation key
	_button_on_bantato_banned_container.connect("pressed", self, "_switch_bantato_container_display")


func add_button(container: InventoryContainer) -> Node:
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


func set_bantato_banned_data(banned_items: Array) -> void:
	"""Set the Bantato-banned items data."""
	bantato_banned_items_container.set_data("BANNED_ITEMS", -1, banned_items)


func add_to_bantato_banned_container(item: ItemParentData) -> void:
	"""Add an item to the Bantato banned items container."""
	if bantato_banned_items_container and bantato_banned_items_container._elements:
		bantato_banned_items_container._elements.add_element(item)


func _switch_bantato_container_display() -> void:
	"""Toggle visibility of Bantato banned items container."""
	if bantato_display_visible:
		# Switch back to items
		items_container.visible = true
		_button_on_items_container.text = "SWITCH_TO_ITEMS"

		bantato_banned_items_container.visible = false
		_button_on_bantato_banned_container.text = "SHOW_BANNED"

		items_container._elements.grab_focus()
	else:
		# Switch to banned items
		items_container.visible = false
		_button_on_items_container.text = "SWITCH_TO_ITEMS"

		bantato_banned_items_container.visible = true
		_button_on_bantato_banned_container.text = "SWITCH_TO_ITEMS"

		if bantato_banned_items_container._elements.get_child_count() > 0:
			bantato_banned_items_container._elements.get_child(0).grab_focus()
		else:
			_button_on_bantato_banned_container.grab_focus()

	bantato_display_visible = not bantato_display_visible