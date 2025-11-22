extends "res://ui/menus/global/popup_manager.gd"


signal banned_element_focused(element, player_index)


func connect_banned_inventory_container(container: InventoryContainer) -> void :
    var inventory = container._elements
    var _err = inventory.connect("element_hovered", self, "_on_banned_element_hovered")
    _err = inventory.connect("element_unhovered", self, "_on_element_unhovered")
    _err = inventory.connect("element_focused", self, "_on_banned_element_focused")
    _err = inventory.connect("element_unfocused", self, "_on_element_unfocused")
    _err = inventory.connect("element_pressed", self, "_on_banned_element_pressed")


func _on_banned_element_hovered(element: InventoryElement) -> void :
	var player_index = _get_player_index_for_control(element)
	if _elements_pressed[player_index] != null:
		return
	element.grab_focus()
	_elements_hovered[player_index] = element
	_elements_focused[player_index] = element
	if _item_popups[player_index]:
		_item_popups[player_index].display_banned_element(element)


func _on_banned_element_focused(element: InventoryElement) -> void :
    var player_index = _get_player_index_for_control(element)
    emit_signal("banned_element_focused", element, player_index)
    if _elements_pressed[player_index] != null:
        return
    _elements_focused[player_index] = element
    if _item_popups[player_index]:
        _item_popups[player_index].display_banned_element(element)


func _on_banned_element_pressed(element: InventoryElement) -> void :
    var player_index = _get_player_index_for_control(element)
    emit_signal("element_pressed", element, player_index, false)
