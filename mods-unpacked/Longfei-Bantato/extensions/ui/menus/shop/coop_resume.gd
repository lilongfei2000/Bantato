extends "res://ui/menus/shop/coop_resume.gd"

# Access BantatoService
var BantatoService

func _update_player_index(player_index: int) -> void :
    ._update_player_index(player_index)
    if not BantatoService:
        BantatoService = get_node("/root/ModLoader/Longfei-Bantato/BantatoService")
    var bans = BantatoService.get_banned_data(player_index)
    _player_gear_container.bantato_set_banned_data(bans)
