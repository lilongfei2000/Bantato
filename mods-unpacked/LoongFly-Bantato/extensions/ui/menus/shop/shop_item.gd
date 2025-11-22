extends "res://ui/menus/shop/shop_item.gd"


var _ban_button
var ban_value

signal ban_button_pressed(shop_item)


func _ready()->void:
	_ban_button = get_ban_button()
	if RunData.is_coop_run:
		setup_for_coop()
	else:
		setup_for_single()


func setup_for_coop() -> void :
	var hbox = HBoxContainer.new()
	hbox.add_child(_ban_button)
	var panel = get_child(0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove_child(panel)
	hbox.add_child(panel)
	add_child(hbox)
	_button.focus_neighbour_left = _ban_button.get_path()
	_ban_button.focus_neighbour_right = _button.get_path()


func setup_for_single() -> void :
	adjust_size()
	add_child(_ban_button)
	move_child(_ban_button, 0)
	_button.focus_neighbour_top = _ban_button.get_path()
	_ban_button.focus_neighbour_bottom = _button.get_path()


func get_ban_button() -> ButtonWithIcon:
	# Create new ban button using ButtonWithIcon scene
	var button_with_icon = load("res://ui/menus/shop/button_with_icon.tscn")
	_ban_button = button_with_icon.instance()
	_ban_button.name = "BanButton"

	# Setup ban button properties
	_ban_button.text = ""
	var icon = _ban_button.get_node("HBoxContainer/GoldIcon")
	icon.set_texture(load("res://mods-unpacked/LoongFly-Bantato/extensions/ui/menus/shop/bantato_ban_icon.png"))
	_ban_button.get_node("HBoxContainer/Label").set("custom_fonts/font", _button.get_node("HBoxContainer/Label").get("custom_fonts/font"))
	_ban_button.get_node("HBoxContainer/GoldIcon").rect_size = _button.get_node("HBoxContainer/GoldIcon").rect_size
	_ban_button.get_node("HBoxContainer/GoldIcon").rect_min_size = _button.get_node("HBoxContainer/GoldIcon").rect_min_size
	_ban_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ban_button.size_flags_horizontal = 0
	_ban_button.connect("pressed", self, "_on_BanButton_pressed")

	return _ban_button
	
	
func adjust_size()->void:
	var panel_container = $"PanelContainer"
	panel_container.set_margin(MARGIN_TOP, 75)
	panel_container.set_custom_minimum_size(Vector2(0, 0))
	panel_container.set_size(Vector2(417, 400))
	
	var margin_container = $"PanelContainer" / "MarginContainer"
	margin_container.set_custom_minimum_size(Vector2(0, 0))
	margin_container.set_size(Vector2(407, 390))
	
	var vbox = $"PanelContainer" / "MarginContainer" / "VBoxContainer"
	vbox.set_custom_minimum_size(Vector2(0, 0))
	vbox.set_size(Vector2(387, 370))

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


func disable_ban_focus()->void :
	_ban_button.focus_mode = FOCUS_NONE
	
	
func enable_ban_focus()->void :
	if active:
		_ban_button.focus_mode = FOCUS_ALL
		

func deactivate()->void :
	_ban_button.disable()
	.deactivate()
	
	
func activate()->void :
	_ban_button.reinitialize_colors(player_index)
	_ban_button.activate()
	.activate()


func update_color()->void :
	.update_color()
	_ban_button.set_color_from_currency(RunData.get_player_currency(player_index))


func _on_BanButton_pressed()->void :
	emit_signal("ban_button_pressed", self)


func set_shop_item(p_item_data:ItemParentData, p_wave_value:int = RunData.current_wave)->void:
	.set_shop_item(p_item_data, p_wave_value)

	update_ban_price(p_item_data)


func update_ban_price(p_item_data:ItemParentData)->void :
	ban_value = RunData.get_ban_price(p_item_data, value, player_index)
	if _ban_button:
		if RunData.is_bannable(p_item_data, player_index):
			_ban_button.set_value(ban_value, RunData.get_player_currency(player_index))
			_ban_button.reinitialize_colors(player_index)
			_ban_button.show()
			_ban_button.activate()
		else:
			_ban_button.hide()
			_ban_button.disable()
