# services/bantato_player_data.gd

extends Reference

const MOD_NAME = "Bantato"
const MOD_LOG = "BantatoPlayerData"
const MIN_UNBANNED_NUM = NB_SHOP_ITEMS * 2

# Banned items for this player with prevent counters
# Structure: {item_id: int}
var _banned_data: Dictionary = {}

# Unbanned item pools: [tier][type]{ItemParentData.my_id: true}
var _unbanned_pools: Array = [] # TODO: check if this pool is necessary
var _bannable_nums: Array


func _init(player_index: int, nums: Array) -> void:
	_bannable_nums = nums
	ModLoaderLog.info("Player %d data initialized" % player_index, MOD_LOG)

# ==================== Public API: Banning ====================

func ban(item: ItemParentData) -> void:
	"""Ban an item and remove it from pools."""
	_banned_data[item.my_id] = 0
	_update_bannable_num(item)


func unban(item_id: String) -> ItemParentData:
	"""Unban an item and add it back to pools. Returns the unbanned item or null."""
	# TODO: implement this correctly
	pass


# ==================== Public API: Queries ====================

func is_banned(item: ItemParentData) -> bool:
	"""Check if an item is banned."""
	return _banned_data.has(item.my_id)


func is_bannable(item: ItemParentData) -> bool:
	var type = 1 if item is WeaponData else 0
	return _bannable_nums[item.tier][type] > MIN_UNBANNED_NUM


func get_ban_price(shop_item: ShopItem) -> int:
	var type = 1 if shop_item.item_data is WeaponData else 0
	var tier = shop_item.item_data.tier
	var bannable_num = _bannable_nums[tier][type]
	return max(1, int(float(shop_item.value) / (bannable_num - 1)))


func get_banned_data() -> Dictionary:
	return _banned_data


func get_unbanned_pool(tier: int, type: int) -> Array:
	"""Get the pool of unbanned items for a specific tier and type."""
	return _unbanned_pools[tier][type].duplicate()

# ==================== Public API: Lifecycle ====================

func clear() -> void:
	"""Clear all banned items and reset pools."""
	_banned_data.clear()
	_bannable_nums.clear()
	_init_nums()


func increment_prevent_count(item_id: String) -> void:
	"""Increment the prevent counter for a banned item."""
	_banned_data[item_id] += 1


func get_prevent_count(item_id: String) -> int:
	"""Get the prevent counter for a banned item."""
	if _banned_data.has(item_id):
		return _banned_data[item_id]
	return 0

# ==================== Serialization ====================

func restore_banned_data(data: Dictionary) -> void:
	"""Restore banned items from deserialized data and update pools."""
	_banned_data = data
	for id in data:
		var item
		if ItemService.is_item_id(id):
			item = ItemService.get_item_from_id(id)
		elif ItemService.is_weapon_id(id):
			item = ItemService.get_weapon_from_weapon_id(id)
		else:
			continue
		_update_bannable_num(item)


# ==================== Private Helpers ====================

func _update_bannable_num(item: ItemParentData) -> void:
	if item is ItemData:
		if item.max_nb == -1:
			_bannable_nums[item.tier][0] -= 1
	elif item is WeaponData:
		_bannable_nums[item.tier][1] -= 1
