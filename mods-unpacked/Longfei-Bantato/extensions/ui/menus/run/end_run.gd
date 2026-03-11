extends "res://ui/menus/run/end_run.gd"

onready var BantatoService = get_node("/root/ModLoader/Longfei-Bantato/BantatoService")


func _ready() -> void:
    var banned_items_container = BantatoService.setup_banned_items_container(_items_container)
    var banned_items = BantatoService.get_banned_data(0)
    BantatoService.set_banned_data(banned_items_container, banned_items)

    _popup_manager.connect_inventory_container(banned_items_container)

    banned_items_container._elements.emit_signal("need_to_sort_inventory")
