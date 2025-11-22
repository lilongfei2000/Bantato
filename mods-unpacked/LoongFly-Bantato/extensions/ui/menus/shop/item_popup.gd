extends "res://ui/menus/shop/item_popup.gd"


func display_banned_element(element: InventoryElement) -> void :
	display_banned_item_data(element.item, element, true)


func display_banned_item_data(item_data: ItemParentData, attachment: Control, is_inventory_element: = false) -> void :
	_item_data = item_data
	_attachment = attachment
	_is_inventory_element = is_inventory_element
	_panel.set_data(item_data, player_index)
	set_synergies_text(item_data)

	_last_wave_info_container.hide()
	if is_inventory_element and item_data is WeaponData and item_data.dmg_dealt_last_wave != 0:
		_last_wave_info_container.display(Text.text("DAMAGE_DEALT_LAST_WAVE", [Text.get_formatted_number(item_data.dmg_dealt_last_wave)], [Sign.POSITIVE]))
	elif is_inventory_element and item_data is ItemData and "item_builder_turret" in item_data.my_id:

		var tracked_id = item_data.my_id

		
		if RunData.tracked_item_effects[player_index][item_data.my_id] == 0:
			var turret_lvl = item_data.my_id.trim_prefix("item_builder_turret_") as int

			if turret_lvl > 0:
				tracked_id = "item_builder_turret_" + str(turret_lvl - 1)

		_last_wave_info_container.display(Text.text("DAMAGE_DEALT_LAST_WAVE", [Text.get_formatted_number(RunData.tracked_item_effects[player_index][tracked_id])], [Sign.POSITIVE]))

	_combine_button.hide()
	_discard_button.hide()
	_cancel_button.hide()

	var stylebox_color = _panel.get_stylebox("panel").duplicate()
	ItemService.change_panel_stylebox_from_tier(stylebox_color, item_data.tier, true)
	_panel.add_stylebox_override("panel", stylebox_color)

	show()
	set_pos_from(attachment, _panel)
