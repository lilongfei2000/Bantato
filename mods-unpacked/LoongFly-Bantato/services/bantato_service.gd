# services/bantato_service.gd

extends Node

class_name BantatoService

const MOD_NAME = "Bantato"
const MOD_LOG = "BantatoService"
const NUM_TIER = 4

const BantatoPlayerData = preload("res://mods-unpacked/LoongFly-Bantato/services/bantato_player_data.gd")

# Player data objects: [BantatoPlayerData, ...] indexed by player_index
var _players: Array = []
var _all_items: Dictionary = {}
var _bannable_nums: Array = []


func _init() -> void:
	ModLoaderLog.info("BantatoService initialized", MOD_LOG)


func _init_all_items() -> void:
	for item in ItemService.items:
		_all_items[item.my_id] = item
	for weapon in ItemService.weapons:
		_all_items[weapon.my_id] = weapon


func _init_nums() -> void:
	for tier in NUM_TIER:
		var item_pool = ItemService.get_pool(tier, ItemService.TierData.ITEMS)
		var item_bannable_num = 0
		for item in item_pool:
			if item.max_nb == -1:
				item_bannable_num += 1
		
		var weapon_pool = ItemService.get_pool(tier, ItemService.TierData.WEAPONS)

		_bannable_nums.append([item_bannable_num, weapon_pool.size()])


# ==================== Public API: Banning ====================

func ban(shop_item: ShopItem, player_index: int) -> void:
	"""
	Ban an item for a player.

	Args:
		item: The item to ban
		player_index: The player's index (0-3)
	"""
	# Ban the item
	_players[player_index].ban(shop_item.item_data)
	# Deduct gold from player
	RunData.remove_currency(shop_item.bantato_ban_value, player_index)
	ModLoaderLog.info("Banned item %s for player %d (cost: %d gold)" % [item.my_id, player_index, price], MOD_LOG)


func unban(item_id: String, player_index: int) -> void:
	"""
	Unban an item for a player.

	Args:
		item_id: The ID of the item to unban
		player_index: The player's index (0-3)
	"""
	var item = _players[player_index].unban(item_id)


# ==================== Public API: Queries ====================

func get_banned_data(player_index: int) -> Dictionary:
	return _players[player_index].get_banned_data()


func get_rand_item_retry(pool: Array, player_index: int) -> ItemParentData:
	var elt
	# TODO: check if possible to loop forever
	while true:
		# Pick random item
		elt = Utils.get_rand_element(pool)
		# Check if banned by Bantato
		if _players[player_index].is_banned(item):
			# Increment prevent counter
			_players[player_index].increment_prevent_count(item_id)
			continue

		break
		
	return elt


func get_rand_item_remove(pool: Array, player_index: int) -> ItemParentData:
	var elt
	while true:
		# Pick random item
		elt = Utils.get_rand_element(pool)
		# Check if banned by Bantato
		if _players[player_index].is_banned(item):
			# Increment prevent counter
			_players[player_index].increment_prevent_count(item_id)
			pool = remove_element_by_id_with_item(pool, elt)
			# TODO: check if possible to result in an empty array
			continue

		break
		
	return elt


func get_item_by_id(id):
	return _all_items[id]


func get_prevent_count(item_id: String, player_index: int) -> int:
	"""
	Get the prevent counter for a banned item.

	Args:
		item_id: The ID of the banned item
		player_index: The player's index (0-3)

	Returns:
		The number of times the item was prevented from appearing
	"""
	return _players[player_index].get_prevent_count(item_id)


func get_ban_price(item: ShopItem, player_index: int) -> int:
	"""
	Calculate the gold cost to ban an item.

	Args:
		item: The item to calculate price for
		player_index: The player's index (0-3)

	Returns:
		The gold cost (minimum 1)
	"""
	return _players[player_index].get_ban_price(item)


func is_bannable(item: ItemParentData, player_index: int) -> bool:
	"""
	Check if an item can be banned.

	Requirements:
	- Item is not already banned
	- At least MIN_UNBANNED_NUM items of this tier/type remain

	Args:
		item: The item to check
		player_index: The player's index (0-3)

	Returns:
		True if the item can be banned, false otherwise
	"""
	# Check if already banned
	return _players[player_index].is_bannable(item)


func get_unbanned_pool(tier: int, type: int, player_index: int) -> Array:
	"""
	Get the pool of unbanned items for a specific tier and type.

	Args:
		tier: The item tier (0-4)
		type: The item type (TierData.ITEMS, TierData.WEAPONS, TierData.ALL_ITEMS)
		player_index: The player's index (0-3)

	Returns:
		Array of ItemParentData objects (not including banned items)
	"""
	return _players[player_index].get_unbanned_pool(tier, type)

# ==================== Public API: Lifecycle ====================

func reset_run(player_count: int = 1) -> void:
	"""
	Reset all data for a new run.

	Args:
		player_count: Number of players in the run
	"""
	if _all_items.size() == 0:
		_init_all_items()

	if _bannable_nums.size() == 0:
		_init_nums()

	_players.clear()

	for i in range(player_count):
		var player_data = BantatoPlayerData.new(i)
		_players.append(player_data, _bannable_nums.duplicate())

	ModLoaderLog.info("Reset Bantato data for %d player(s)" % player_count, MOD_LOG)


# ==================== Serialization ====================

func serialize() -> Array:
	"""
	Serialize all Bantato data for saving.

	Returns:
		Array containing serialized data for each player
		Format: [[player_0_items], [player_1_items], ...]
	"""
	var serialized_data = []

	for player in _players:
		serialized_data.append(player.get_banned_data())

	return serialized_data


func deserialize(data: Array) -> void:
	"""
	Deserialize Bantato data from save.

	Args:
		data: Array containing serialized data for each player
	"""
	_players.clear()

	for player_index in range(data.size()):
		var player_data = BantatoPlayerData.new(player_index)
		
		if data[player_index].size() > 0:
			player_data.restore_banned_data(data[player_index])
		
		_players.append(player_data)

	ModLoaderLog.info("Deserialized Bantato data for %d player(s)" % data.size(), MOD_LOG)


# ==================== Private Helpers ====================

func _is_valid_player_index(player_index: int) -> bool:
	"""Check if player_index is within valid bounds."""
	return player_index >= 0 and player_index < _players.size()


func _get_total_item_count(item: ItemParentData) -> int:
	"""Get total count of items in this tier/type."""
	var tier_data = ItemService._tiers_data[item.tier]

	if item is ItemData:
		return tier_data[ItemService.TierData.ITEMS].size()
	elif item is WeaponData:
		return tier_data[ItemService.TierData.WEAPONS].size()

	return 1


func _get_unbanned_item_count(item: ItemParentData, player_index: int) -> int:
	"""Get count of unbanned items in this tier/type."""
	var item_type = ItemService.TierData.ITEMS
	if item is WeaponData:
		item_type = ItemService.TierData.WEAPONS
	
	return _players[player_index].get_unbanned_count(item.tier, item_type)
