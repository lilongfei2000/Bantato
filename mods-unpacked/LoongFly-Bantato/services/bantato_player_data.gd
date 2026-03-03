# services/bantato_player_data.gd

extends Reference

const MOD_NAME = "Bantato"
const MOD_LOG = "BantatoPlayerData"
const MIN_UNBANNED_NUM = 5

# Banned items for this player with prevent counters
# Structure: {item_id: [ItemParentData, int]}
var _banned_data: Dictionary = {}

# Unbanned item pools: [tier][type][ItemParentData, ...]
var _unbanned_pools: Array = []
var _bannable_nums: Array = []


func _init(player_index: int, tier_count: int) -> void:
	"""Initialize player data with empty pools."""
	_initialize_pools(tier_count)
	ModLoaderLog.info("Player %d data initialized" % player_index, MOD_LOG)


func _initialize_pools(tier_count: int) -> void:
	"""Initialize unbanned item pools from ItemService."""
	_unbanned_pools.clear()
	_bannable_nums.clear()

	var pool: Array
	var item_ids: Dictionary
	var weapon_ids: Dictionary
	var item_bannable_num: int

	for tier in tier_count:
		pool = ItemService.get_pool(tier, ItemService.TierData.ITEMS)
		item_ids = {}
		item_bannable_num = 0
		for item in pool:
			item_ids[item.my_id] = true
			if item.max_nb == -1:
				item_bannable_num += 1
		
		pool = ItemService.get_pool(tier, ItemService.TierData.WEAPONS)
		var weapon_ids = {}
		for weapon in pool:
			weapon_ids[weapon.my_id] = true

		_unbanned_pools.append([item_ids, weapon_ids])
		_bannable_nums.append([item_bannable_num, weapon_ids.size()])


# ==================== Public API: Banning ====================

func ban(item: ItemParentData) -> void:
	"""Ban an item and remove it from pools."""
	_banned_data[item.my_id] = [item, 0]
	if item is ItemData:
		_unbanned_pools[item.tier][0].erase(item.my_id)
		if item.max_nb == -1:
			_bannable_nums[item.tier][0] -= 1
	elif item is WeaponData:
		_unbanned_pools[item.tier][1].erase(item.my_id)
		_bannable_nums[item.tier][1] -= 1


func unban(item_id: String) -> ItemParentData:
	"""Unban an item and add it back to pools. Returns the unbanned item or null."""
	# TODO: implement this correctly
	if _banned_data.has(item_id):
		var item_data = _banned_data[item_id]
		var item = item_data[0]
		_banned_data.erase(item_id)
		_add_item_to_pools(item)
		return item
	return null


# ==================== Public API: Queries ====================

func is_banned(item: ItemParentData) -> bool:
	"""Check if an item is banned."""
	return _banned_data.has(item.my_id)


func is_bannable(item: ItemParentData) -> bool:
	var type = 1 if item is WeaponData else 0
	if _bannable_nums[item.tier][type] <= MIN_UNBANNED_NUM or is_banned(item):
		return false
	return true


func get_ban_price(shop_item: ShopItem) -> int:
	var type = 1 if shop_item.item_data is WeaponData else 0
	var tier = shop_item.item_data.tier
	var bannable_num = _bannable_nums[tier][type]
	return max(1, int(float(shop_item.value) / (bannable_num - 1))


func get_banned_items() -> Array:
	"""Get all banned items."""
	var items = []
	for item_data in _banned_data.values():
		items.append(item_data[0])
	return items


func get_banned_data() -> Dictionary:
	return _banned_data


func get_unbanned_pool(tier: int, type: int) -> Array:
	"""Get the pool of unbanned items for a specific tier and type."""
	return _unbanned_pools[tier][type].duplicate()


func get_unbanned_count(tier: int, type: int) -> int:
	"""Get count of unbanned items for a tier and type (ITEMS or WEAPONS)."""
	return _unbanned_pools[tier][type].size()


# ==================== Public API: Lifecycle ====================

func clear() -> void:
	"""Clear all banned items and reset pools."""
	_banned_data.clear()
	_initialize_pools(_unbanned_pools.size())


func increment_prevent_count(item_id: String) -> void:
	"""Increment the prevent counter for a banned item."""
		_banned_data[item_id][1] += 1


func get_prevent_count(item_id: String) -> int:
	"""Get the prevent counter for a banned item."""
	if _banned_data.has(item_id):
		return _banned_data[item_id][1]
	return 0


func restore_banned_data(items: Array) -> void:
	"""Restore banned items from deserialized data and update pools."""
	_banned_data.clear()
	for item in items:
		_banned_data[item.my_id] = [item, 0]
		_remove_item_from_pools(item)


# ==================== Serialization ====================

func serialize() -> Array:
	"""Serialize banned items for saving."""
	var serialized = []
	for item_data in _banned_data.values():
		serialized.append(item_data[0].serialize())
	return serialized


# ==================== Private Helpers ====================

func _remove_item_from_pools(item: ItemParentData) -> void:
	"""Remove an item from all unbanned pools."""
	var pools = _unbanned_pools[item.tier]
	_remove_from_list(pools[ItemService.TierData.ALL_ITEMS], item)
	
	if item is ItemData:
		_remove_from_list(pools[ItemService.TierData.ITEMS], item)
	elif item is WeaponData:
		_remove_from_list(pools[ItemService.TierData.WEAPONS], item)


func _add_item_to_pools(item: ItemParentData) -> void:
	"""Add an item back to unbanned pools."""	
	var pools = _unbanned_pools[item.tier]
	pools[ItemService.TierData.ALL_ITEMS].append(item.duplicate())
	
	if item is ItemData:
		pools[ItemService.TierData.ITEMS].append(item.duplicate())
	elif item is WeaponData:
		pools[ItemService.TierData.WEAPONS].append(item.duplicate())


func _remove_from_list(list: Array, item: ItemParentData) -> void:
	"""Remove an item from a list by ID."""
	for i in range(list.size()):
		if list[i].my_id == item.my_id:
			list.remove(i)
			return
