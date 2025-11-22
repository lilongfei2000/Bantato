extends "res://ui/menus/shop/coop_shop.gd"


func _on_banned_element_focused(element: InventoryElement, player_index: int) -> void :
    _on_element_focused(element, player_index)
    _get_coop_player_container(player_index).on_show_banned_inventory_popup()
    