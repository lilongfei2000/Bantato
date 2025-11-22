extends "res://singletons/player_run_data.gd"


var banned_items: = []
var _unbanned_tiers_data: Array = []


func check_unbanned_tiers_data() -> void:
	if _unbanned_tiers_data.size() == 0:
		init_unbanned_tiers_data()
		
		
func erase_item(arr: Array, item: ItemParentData):
	for idx in range(arr.size()):
		if(item.my_id == arr[idx].my_id):
			arr.remove(idx)
			return


func erase_from_pool(item: ItemParentData):
	erase_item(_unbanned_tiers_data[item.tier][ItemService.TierData.ALL_ITEMS], item)
	if item is ItemData:
		erase_item(_unbanned_tiers_data[item.tier][ItemService.TierData.ITEMS], item)
	elif item is WeaponData:
		erase_item(_unbanned_tiers_data[item.tier][ItemService.TierData.WEAPONS], item)


func init_unbanned_tiers_data() -> void :
	_unbanned_tiers_data = ItemService._tiers_data.duplicate(true)
	for banned_item in banned_items:
		erase_from_pool(banned_item)


func duplicate() -> PlayerRunData:
	var copy = .duplicate()
	copy.banned_items = banned_items.duplicate()
	check_unbanned_tiers_data()
	copy._unbanned_tiers_data = _unbanned_tiers_data.duplicate()
	return copy


func serialize() -> Dictionary:
	var data = .serialize()
	var serialized_banned_items: = []
	for banned_item in banned_items:
		serialized_banned_items.push_back(banned_item.serialize())
	data["banned_items"] = serialized_banned_items
	return data


func deserialize(data: Dictionary) -> PlayerRunData:
	.deserialize(data)
	_unbanned_tiers_data = []
	if data.has("banned_items"):
		for banned_item in data["banned_items"]:

			if banned_item is String:
				continue
			
			var banned_item_data = ItemService.get_element(ItemService.items, banned_item.my_id)
			if banned_item_data == null:
				banned_item_data = ItemService.get_element(ItemService.weapons, banned_item.my_id)
			banned_item_data = banned_item_data.duplicate()
			banned_item_data.deserialize_and_merge(banned_item)
			
			banned_items.push_back(banned_item_data)

	return self


func ban_item(item: ItemParentData) -> void :
	banned_items.push_back(item) 
	check_unbanned_tiers_data()
	erase_from_pool(item)


func get_unbanned_num(item: ItemParentData)->int :
	check_unbanned_tiers_data()
	if item is ItemData:
		return _unbanned_tiers_data[item.tier][ItemService.TierData.ITEMS].size()
	elif item is WeaponData:
		return _unbanned_tiers_data[item.tier][ItemService.TierData.WEAPONS].size()
	return 0


func is_bannable(item: ItemParentData)->bool :
	check_unbanned_tiers_data()
	if item is ItemData:
		return _unbanned_tiers_data[item.tier][ItemService.TierData.ITEMS].size() > ItemService.MIN_UNBANNED_NUM
	elif item is WeaponData:
		return _unbanned_tiers_data[item.tier][ItemService.TierData.WEAPONS].size() > ItemService.MIN_UNBANNED_NUM
	return false


func get_unbanned_pool(item_tier: int, type: int) -> Array:
	check_unbanned_tiers_data()
	return _unbanned_tiers_data[item_tier][type].duplicate()
