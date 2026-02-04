extends "res://ui/menus/shop/shop_item.gd"

# Access BantatoService
onready var BantatoService = get_node("/root/ModLoader/LoongFly-Bantato/BantatoService")

var _bantato_ban_button: ButtonWithIcon
var bantato_ban_value: int

signal bantato_ban_button_pressed(shop_item)


func _ready() -> void:
	# Setup Bantato ban button
	_bantato_ban_button = _create_bantato_ban_button()

	if RunData.is_coop_run:
		_setup_bantato_button_for_coop()
	else:
		_setup_bantato_button_for_single()


func _create_bantato_ban_button() -> ButtonWithIcon:
	"""Create the Bantato-specific ban button (gold-based)."""
	var button_with_icon = load("res://ui/menus/shop/button_with_icon.tscn")
	var button = button_with_icon.instance()
	button.name = "BantatoBanButton"

	# Setup button properties
	button.text = ""
	var icon = button.get_node("HBoxContainer/GoldIcon")
	icon.set_texture(load("res://mods-unpacked/LoongFly-Bantato/extensions/ui/menus/shop/bantato_ban_icon.png"))
	button.get_node("HBoxContainer/Label").set("custom_fonts/font", _button.get_node("HBoxContainer/Label").get("custom_fonts/font"))
	button.get_node("HBoxContainer/GoldIcon").rect_size = _button.get_node("HBoxContainer/GoldIcon").rect_size
	button.get_node("HBoxContainer/GoldIcon").rect_min_size = _button.get_node("HBoxContainer/GoldIcon").rect_min_size
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.size_flags_horizontal = 0

	# Connect to Bantato ban handler
	button.connect("pressed", self, "_on_BantatoBanButton_pressed")

	return button


func _setup_bantato_button_for_coop() -> void:
	"""Position Bantato ban button for coop mode."""
	# Add Bantato button to existing button container
	var button_container = _bantato_ban_button.get_parent()
	if button_container == null:
		# Create a new HBoxContainer if it doesn't exist
		var hbox = HBoxContainer.new()
		hbox.add_child(_bantato_ban_button)
		var panel = get_child(0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		remove_child(panel)
		hbox.add_child(panel)
		add_child(hbox)
	else:
		button_container.add_child(_bantato_ban_button)

	# Focus navigation
	_button.focus_neighbour_left = _bantato_ban_button.get_path()
	_bantato_ban_button.focus_neighbour_right = _button.get_path()


func _setup_bantato_button_for_single() -> void:
	"""Position Bantato ban button for single-player mode."""
	adjust_size()

	# Position BELOW the game's ban button, above the buy button
	var panel_container = $"PanelContainer"
	panel_container.set_margin(MARGIN_TOP, 120)  # Increased to accommodate both buttons

	add_child(_bantato_ban_button)
	move_child(_bantato_ban_button, 1)  # Position after game's ban button

	# Focus navigation
	_button.focus_neighbour_top = _bantato_ban_button.get_path()
	_bantato_ban_button.focus_neighbour_bottom = _button.get_path()


func adjust_size() -> void:
	"""Adjust item card size to fit Bantato button."""
	var panel_container = $"PanelContainer"
	panel_container.set_margin(MARGIN_TOP, 120)  # Increased from 75
	panel_container.set_custom_minimum_size(Vector2(0, 0))
	panel_container.set_size(Vector2(417, 445))  # Increased height from 400

	var margin_container = $"PanelContainer" / "MarginContainer"
	margin_container.set_custom_minimum_size(Vector2(0, 0))
	margin_container.set_size(Vector2(407, 435))

	var vbox = $"PanelContainer" / "MarginContainer" / "VBoxContainer"
	vbox.set_custom_minimum_size(Vector2(0, 0))
	vbox.set_size(Vector2(387, 415))

	var empty_space = $"PanelContainer" / "MarginContainer" / "VBoxContainer" / "EmptySpace"
	empty_space.set_custom_minimum_size(Vector2(0, 0))
	empty_space.set_size(Vector2(387, 147))

	var item_desc = $"PanelContainer" / "MarginContainer" / "VBoxContainer" / "ItemDescription"
	item_desc.set_custom_minimum_size(Vector2(0, 0))
	item_desc.set_size(Vector2(387, 147))

	var scroll_container = $"PanelContainer" / "MarginContainer" / "VBoxContainer" / "ItemDescription" / "ScrollContainer"
	scroll_container.set_custom_minimum_size(Vector2(0, 210))
	scroll_container.set_size(Vector2(321, 210))

	var scroll_vbox = $"PanelContainer" / "MarginContainer" / "VBoxContainer" / "ItemDescription" / "ScrollContainer" / "VBoxContainer"
	scroll_vbox.set_custom_minimum_size(Vector2(0, 210))
	scroll_vbox.set_size(Vector2(321, 210))


func deactivate() -> void:
	"""Deactivate the shop item and both ban buttons."""
	.deactivate()  # Call base deactivate (handles game's ban button)

	if _bantato_ban_button:
		_bantato_ban_button.disable()


func activate() -> void:
	"""Activate the shop item and manage Bantato ban button visibility."""
	.activate()  # Call base activate (handles game's ban button)

	if _bantato_ban_button:
		update_bantato_ban_button()
		_bantato_ban_button.reinitialize_colors(player_index)


func update_color() -> void:
	"""Update colors for both buy button and Bantato ban button."""
	.update_color()  # Call base update_color

	if _bantato_ban_button:
		_bantato_ban_button.set_color_from_currency(RunData.get_player_currency(player_index))


func update_bantato_ban_button() -> void:
	"""Update Bantato ban button visibility and state."""
	if not BantatoService:
		return

	# Check if item is bannable via Bantato
	if BantatoService.is_bannable(item_data, player_index):
		# Update price
		bantato_ban_value = BantatoService.get_ban_price(item_data, player_index)
		_bantato_ban_button.set_value(bantato_ban_value, RunData.get_player_currency(player_index))

		# Show and enable
		if not RunData.is_coop_run:
			_bantato_ban_button.show()
		_bantato_ban_button.activate()
	else:
		# Hide and disable
		_bantato_ban_button.hide()
		_bantato_ban_button.disable()


func set_shop_item(p_item_data: ItemParentData, p_wave_value: int = RunData.current_wave) -> void:
	"""Set the shop item data and update Bantato button."""
	.set_shop_item(p_item_data, p_wave_value)  # Call base method

	if _bantato_ban_button:
		update_bantato_ban_button()


func _on_BantatoBanButton_pressed() -> void:
	"""Handle Bantato ban button press."""
	if not BantatoService:
		return

	# Ban the item using BantatoService
	BantatoService.ban_item(item_data, player_index)

	# Signal that item was banned
	emit_signal("bantato_ban_button_pressed", self)