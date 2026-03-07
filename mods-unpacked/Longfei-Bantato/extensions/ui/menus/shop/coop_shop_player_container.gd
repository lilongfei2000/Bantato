extends "res://ui/menus/shop/coop_shop_player_container.gd"


func bantato_on_show_inventory_popup() -> void:
	item_popup.set_synergies_visible(_should_show_synergies())
	item_popup.hide_hints()
