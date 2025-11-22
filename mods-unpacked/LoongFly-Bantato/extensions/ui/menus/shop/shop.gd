extends "res://ui/menus/shop/shop.gd"


func _on_banned_element_focused(element: InventoryElement, player_index: int) -> void:
    _on_element_focused(element, player_index)
