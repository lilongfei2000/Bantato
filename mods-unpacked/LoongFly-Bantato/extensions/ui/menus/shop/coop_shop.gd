extends "res://ui/menus/shop/coop_shop.gd"


func _bantato_on_element_focused(element: InventoryElement, player_index: int) -> void :
    _on_element_focused(element, player_index)
    _get_coop_player_container(player_index).bantato_on_show_inventory_popup()
    