extends "res://ui/menus/run/coop_end_run.gd"

onready var BantatoService = get_node("/root/ModLoader/Longfei-Bantato/BantatoService")


func _ready() -> void :
    var player_count: int = RunData.get_player_count()

    for player_index in player_count:
        var player_container = player_containers[player_index]
        var gear_container = player_container.items_container.get_parent()
        var banned_items_container = gear_container.bantato_banned_items_container

        var banned_items = BantatoService.get_banned_data(player_index)
        BantatoService.set_banned_data(banned_items_container, banned_items)

        _popup_manager.connect_inventory_container(banned_items_container)
