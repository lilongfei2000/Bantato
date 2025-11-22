extends "res://singletons/run_data.gd"


func ban_item(item: ItemParentData, player_index: int) -> void :
	players_data[player_index].ban_item(item)
	

func get_player_banned_items(player_index: int) -> Array :
	assert (player_index >= 0)
	if player_index == DUMMY_PLAYER_INDEX:
		return []
	return players_data[player_index].banned_items.duplicate()
	

func get_ban_price(item: ItemParentData, value: int, player_index: int)->int :
	var total_num = ItemService.get_total_num(item)
	var banned_num = total_num - players_data[player_index].get_unbanned_num(item)
	var factor = float(banned_num) / (total_num - ItemService.MIN_UNBANNED_NUM) #+ 0.25
	return max(1, value * factor) as int
	

func is_bannable(item: ItemParentData, player_index: int)->bool :
	return players_data[player_index].is_bannable(item)


func get_unbanned_pool(item_tier: int, type: int, player_index: int) -> Array:
	return players_data[player_index].get_unbanned_pool(item_tier, type)
