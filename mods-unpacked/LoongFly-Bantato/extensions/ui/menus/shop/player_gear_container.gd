extends "res://ui/menus/shop/player_gear_container.gd"


var banned_items_container
var _button_on_banned_items_container
var _button_on_items_container


func _ready() -> void :
	setup_banned_items_container()

	_button_on_banned_items_container = add_button(banned_items_container)
	_button_on_banned_items_container.text = "SWITCH_TO_ITEMS"
	_button_on_banned_items_container.connect("pressed", self, "_switch_container_display")

	_button_on_items_container = add_button(items_container)
	_button_on_items_container.text = "SWITCH_TO_BANNED_ITEMS"
	_button_on_items_container.connect("pressed", self, "_switch_container_display")


func setup_banned_items_container() -> void:
	# Setup banned items container
	if RunData.is_coop_run:
		banned_items_container = load("res://ui/menus/shop/coop_inventory_container.tscn").instance()
		items_container.add_constant_override("separation", 10)
		banned_items_container.add_constant_override("separation", 10)
		weapons_container.add_constant_override("separation", 10)
		banned_items_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		banned_items_container = load("res://ui/menus/shop/inventory_container.tscn").instance()
	banned_items_container.visible = false
	banned_items_container.reserve_column_count = items_container.reserve_column_count
	banned_items_container.reserve_row_count = items_container.reserve_row_count
	banned_items_container.rect_size = items_container.rect_size
	add_child(banned_items_container)
	move_child(banned_items_container, items_container.get_index())


func add_button(container: InventoryContainer) -> Node:
	# Create toggle button
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


func _switch_container_display() -> void:
	if banned_items_container.visible:
		banned_items_container.visible = false
		items_container.visible = true
		_button_on_items_container.grab_focus()
	else:
		items_container.visible = false
		banned_items_container.visible = true
		_button_on_banned_items_container.grab_focus()


func set_banned_data(banned_items: Array) -> void:
	banned_items_container.set_data("BANNED_ITEMS", -1, banned_items)
