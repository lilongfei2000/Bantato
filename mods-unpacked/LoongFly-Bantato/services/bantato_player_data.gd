# services/bantato_player_data.gd

extends Reference

const MOD_NAME = "Bantato"
const MOD_LOG = "BantatoPlayerData"

# Banned items for this player with prevent counters
# Structure: {item_id: [ItemParentData, int]}
var _banned_items: Dictionary = {}

# Unbanned item pools: {tier: {type: [ItemParentData, ...]}}
var _unbanned_pools: Dictionary = {}


func _init(player_index: int, tier_count: int) -> void:
	"""Initialize player data with empty pools."""
	_initialize_pools(tier_count)
	ModLoaderLog.info("Player %d data initialized" % player_index, MOD_LOG)


func _initialize_pools(tier_count: int) -> void:
	"""Initialize unbanned item pools from ItemService."""
	_unbanned_pools.clear()
	
	for tier in tier_count:
		_unbanned_pools[tier] = {
			ItemService.TierData.ALL_ITEMS: ItemService._tiers_data[tier][ItemService.TierData.ALL_ITEMS].duplicate(),
			ItemService.TierData.ITEMS: ItemService._tiers_data[tier][ItemService.TierData.ITEMS].duplicate(),
			ItemService.TierData.WEAPONS: ItemService._tiers_data[tier][ItemService.TierData.WEAPONS].duplicate()
		}


# ==================== Public API: Banning ====================

func ban(item: ItemParentData) -> void:
	"""Ban an item and remove it from pools."""
	_banned_items[item.my_id] = [item, 0]
	_remove_item_from_pools(item)


func unban(item_id: String) -> ItemParentData:
	"""Unban an item and add it back to pools. Returns the unbanned item or null."""
	if _banned_items.has(item_id):
		var item_data = _banned_items[item_id]
		var item = item_data[0]
		_banned_items.erase(item_id)
		_add_item_to_pools(item)
		return item
	return null


# ==================== Public API: Queries ====================

func is_banned(item: ItemParentData) -> bool:
	"""Check if an item is banned."""
	return _banned_items.has(item.my_id)


func get_banned_items() -> Array:
	"""Get all banned items."""
	var items = []
	for item_data in _banned_items.values():
		items.append(item_data[0])
	return items


func get_unbanned_pool(tier: int, type: int) -> Array:
	"""Get the pool of unbanned items for a specific tier and type."""
	if not _unbanned_pools.has(tier):
		return []
	if not _unbanned_pools[tier].has(type):
		return []
	return _unbanned_pools[tier][type].duplicate()


func get_unbanned_count(tier: int, item_type: int) -> int:
	"""Get count of unbanned items for a tier and type (ITEMS or WEAPONS)."""
	if not _unbanned_pools.has(tier):
		return 0
	if not _unbanned_pools[tier].has(item_type):
		return 0
	return _unbanned_pools[tier][item_type].size()


# ==================== Public API: Lifecycle ====================

func clear() -> void:
	"""Clear all banned items and reset pools."""
	_banned_items.clear()
	_initialize_pools(_unbanned_pools.size())


func increment_prevent_count(item_id: String) -> void:
	"""Increment the prevent counter for a banned item."""
		_banned_items[item_id][1] += 1


func get_prevent_count(item_id: String) -> int:
	"""Get the prevent counter for a banned item."""
	if _banned_items.has(item_id):
		return _banned_items[item_id][1]
	return 0


func restore_banned_items(items: Array) -> void:
	"""Restore banned items from deserialized data and update pools."""
	_banned_items.clear()
	for item in items:
		_banned_items[item.my_id] = [item, 0]
		_remove_item_from_pools(item)


# ==================== Serialization ====================

func serialize() -> Array:
	"""Serialize banned items for saving."""
	var serialized = []
	for item_data in _banned_items.values():
		serialized.append(item_data[0].serialize())
	return serialized


# ==================== Private Helpers ====================

func _remove_item_from_pools(item: ItemParentData) -> void:
	"""Remove an item from all unbanned pools."""
	if not _unbanned_pools.has(item.tier):
		return
	
	var pools = _unbanned_pools[item.tier]
	_remove_from_list(pools[ItemService.TierData.ALL_ITEMS], item)
	
	if item is ItemData:
		_remove_from_list(pools[ItemService.TierData.ITEMS], item)
	elif item is WeaponData:
		_remove_from_list(pools[ItemService.TierData.WEAPONS], item)


func _add_item_to_pools(item: ItemParentData) -> void:
	"""Add an item back to unbanned pools."""
	if not _unbanned_pools.has(item.tier):
		return
	
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
