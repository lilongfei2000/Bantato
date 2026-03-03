# services/bantato_service.gd

extends Node

class_name BantatoService

const MOD_NAME = "Bantato"
const MOD_LOG = "BantatoService"

const BantatoPlayerData = preload("res://mods-unpacked/LoongFly-Bantato/services/bantato_player_data.gd")

# Player data objects: [BantatoPlayerData, ...] indexed by player_index
var _players: Array = []


func _init() -> void:
	ModLoaderLog.info("BantatoService initialized", MOD_LOG)


# ==================== Public API: Banning ====================

func ban(item: ItemParentData, player_index: int) -> void:
	"""
	Ban an item for a player.

	Args:
		item: The item to ban
		player_index: The player's index (0-3)
	"""
	# Ban the item
	_players[player_index].ban(item)

	# Deduct gold from player
	var price = get_ban_price(item, player_index)
	RunData.remove_currency(price, player_index)

	ModLoaderLog.info("Banned item %s for player %d (cost: %d gold)" % [item.my_id, player_index, price], MOD_LOG)


func unban(item_id: String, player_index: int) -> void:
	"""
	Unban an item for a player.

	Args:
		item_id: The ID of the item to unban
		player_index: The player's index (0-3)
	"""
	if not _is_valid_player_index(player_index):
		ModLoaderLog.error("Invalid player index: %d" % player_index, MOD_LOG)
		return

	var item = _players[player_index].unban(item_id)
	
	if item != null:
		ModLoaderLog.info("Unbanned item %s for player %d" % [item_id, player_index], MOD_LOG)
	else:
		ModLoaderLog.warning("Item %s not found in banned list for player %d" % [item_id, player_index], MOD_LOG)


# ==================== Public API: Queries ====================

func get_banned_items(player_index: int) -> Array:
	"""
	Get all banned items for a player.

	Args:
		player_index: The player's index (0-3)

	Returns:
		Array of ItemParentData objects
	"""
	return _players[player_index].get_banned_items()


func get_banned_data(player_index: int) -> Dictionary:
	return _players[player_index].get_banned_data()


func is_item_banned(item: ItemParentData, player_index: int) -> bool:
	"""
	Check if an item is banned for a player.

	Args:
		item: The item to check
		player_index: The player's index (0-3)

	Returns:
		True if the item is banned, false otherwise
	"""
	return _players[player_index].is_banned(item)


func increment_prevent_count(item_id: String, player_index: int) -> void:
	"""
	Increment the prevent counter for a banned item.

	Args:
		item_id: The ID of the banned item
		player_index: The player's index (0-3)
	"""
	_players[player_index].increment_prevent_count(item_id)


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
	_players.clear()
	
	var tier_count = ItemService._tiers_data.size()
	
	for i in range(player_count):
		var player_data = BantatoPlayerData.new(i, tier_count)
		_players.append(player_data)

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
		serialized_data.append(player.serialize())

	return serialized_data


func deserialize(data: Array) -> void:
	"""
	Deserialize Bantato data from save.

	Args:
		data: Array containing serialized data for each player
	"""
	_players.clear()
	
	var tier_count = ItemService._tiers_data.size()

	for player_index in range(data.size()):
		var player_data = BantatoPlayerData.new(player_index, tier_count)
		
		if data[player_index].size() > 0:
			var restored_items = []
			for serialized_item in data[player_index]:
				var item_data = ItemService.get_element(ItemService.items, serialized_item.my_id)
				
				if item_data == null:
					item_data = ItemService.get_element(ItemService.weapons, serialized_item.my_id)
				
				if item_data != null:
					item_data = item_data.duplicate()
					item_data.deserialize_and_merge(serialized_item)
					restored_items.append(item_data)
			
			player_data.restore_banned_items(restored_items)
		
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
