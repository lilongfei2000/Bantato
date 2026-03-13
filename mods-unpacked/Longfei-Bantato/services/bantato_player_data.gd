# services/bantato_player_data.gd

extends Reference

const MOD_NAME = "Bantato"
const MOD_LOG = "BantatoPlayerData"

# Banned items for this player with prevent counters
# Structure: {item_id: int}
var _banned_data: Dictionary = {}

# Unbanned item pools: [tier][type]{ItemParentData.my_id: true}
var _unbanned_pools: Array = [] # TODO: check if this pool is necessary
var _bannable_nums: Array


func _init(data: Dictionary = {}, nums: Array = []) -> void:
	_bannable_nums = nums
	_banned_data = data

# ==================== Public API: Banning ====================

func ban(item: ItemParentData) -> void:
	"""Ban an item and remove it from pools."""
	_banned_data[item.my_id] = 1
	update_bannable_num(item)


func update_bannable_num(item: ItemParentData) -> void:
	if item is ItemData:
		if item.max_nb == -1:
			_bannable_nums[item.tier][0] -= 1
	elif item is WeaponData:
		_bannable_nums[item.tier][1] -= 1


func unban(_item_id: String):
	"""Unban an item and add it back to pools. Returns the unbanned item or null."""
	# TODO: implement this correctly
	pass


# ==================== Public API: Queries ====================

func is_banned(item: ItemParentData) -> bool:
	"""Check if an item is banned."""
	return _banned_data.has(item.my_id)


func get_banned_data() -> Dictionary:
	return _banned_data


func get_bannable_num_of(item: ItemParentData) -> int:
	var type = 1 if item is WeaponData else 0
	return _bannable_nums[item.tier][type]


func get_ban_price(shop_item: ShopItem) -> int:
	var type = 1 if shop_item.item_data is WeaponData else 0
	var tier = shop_item.item_data.tier
	var bannable_num = _bannable_nums[tier][type]
	return max(1, float(shop_item.value) / (bannable_num - 1)) as int


func get_unbanned_pool(_tier: int, _type: int):
	"""Get the pool of unbanned items for a specific tier and type."""
	pass


func get_prevent_count(item_id: String) -> int:
	"""Get the prevent counter for a banned item."""
	if _banned_data.has(item_id):
		return _banned_data[item_id]
	return 0


func increment_prevent_count(item_id: String) -> void:
	"""Increment the prevent counter for a banned item."""
	_banned_data[item_id] += 1

# ==================== Public API: Lifecycle ====================

func clear() -> void:
	"""Clear all banned items and reset pools."""
	_banned_data.clear()
	_bannable_nums.clear()


func set_bannable_nums(nums: Array) -> void:
	_bannable_nums = nums

# ==================== Serialization ====================

func serialize() -> Dictionary:
	return {
		'banned_data': _banned_data,
		'bannable_nums': _bannable_nums
	}
