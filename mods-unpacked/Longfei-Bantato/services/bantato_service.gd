# services/bantato_service.gd

extends Node

class_name BantatoService

const MOD_NAME = "Bantato"
const MOD_LOG = "BantatoService"
const NUM_TIER = 4
# Translation keys for UI strings
const STR_BANNED_ITEMS = "BANTATO_BANNED"
const STR_SWITCH_TO_BANNED = "BANTATO_SWITCH_TO_BANNED"
const STR_SWITCH_TO_ITEMS = "BANTATO_SWITCH_TO_ITEMS"

const BantatoPlayerData = preload("res://mods-unpacked/Longfei-Bantato/services/bantato_player_data.gd")

signal banned_item_prevent(item, player_index)

# Player data objects: [BantatoPlayerData, ...] indexed by player_index
var _players: Array = []
var _all_items: Dictionary = {}
var _bannable_nums: Array = [[0, 0], [0, 0], [0, 0], [0, 0]]


func _init() -> void:
	ModLoaderLog.info("BantatoService initialized", MOD_LOG)


func _init_all_items() -> void:
	for item in ItemService.items:
		_all_items[item.my_id] = item
	for weapon in ItemService.weapons:
		_all_items[weapon.my_id] = weapon


func _init_nums() -> void:
	for tier in NUM_TIER:
		var type = ItemService.TierData.ITEMS
		var item_pool = ItemService.get_pool(tier, type)
		var item_bannable_num = 0
		for item in item_pool:
			if item.max_nb == -1:
				item_bannable_num += 1
		
		var weapon_pool = ItemService.get_pool(tier, ItemService.TierData.WEAPONS)

		_bannable_nums[tier] = [item_bannable_num, weapon_pool.size()]


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
	RunData.remove_gold(shop_item.bantato_ban_value, player_index)


func update_ban_num(item: ItemParentData, player_index: int) -> void:
	_players[player_index].update_bannable_num(item)


func unban(_item_id: String, _player_index: int) -> void:
	"""
	Unban an item for a player.

	Args:
		item_id: The ID of the item to unban
		player_index: The player's index (0-3)
	"""
	pass


# ==================== Public API: Queries ====================

func get_banned_data(player_index: int) -> Dictionary:
	return _players[player_index].get_banned_data()


# Possible to be a dead loop because of the native item selection rule
func get_rand_item_retry(pool: Array, backup_pool: Array, player_index: int) -> ItemParentData:
	var elt
	var current_pool = backup_pool
	for e in pool:
		if not _players[player_index].is_banned(e):
			current_pool = pool
			break
	while true:
		# Pick random item
		elt = Utils.get_rand_element(current_pool)
		# Check if banned by Bantato
		if _players[player_index].is_banned(elt):
			# Increment prevent counter
			_players[player_index].increment_prevent_count(elt.my_id)
			emit_signal("banned_item_prevent", elt, player_index)
			
			continue

		break
		
	return elt


func get_rand_item_remove(pool: Array, backup_pool: Array, player_index: int) -> ItemParentData:
	var elt
	var current_pool = pool
	while true:
		# Pick random item
		if current_pool.size() == 0:
			current_pool = backup_pool
		elt = Utils.get_rand_element(current_pool)
		# Check if banned by Bantato
		if _players[player_index].is_banned(elt):
			# Increment prevent counter
			_players[player_index].increment_prevent_count(elt.my_id)
			emit_signal("banned_item_prevent", elt, player_index)

			current_pool = ItemService.remove_element_by_id_with_item(current_pool, elt)
			
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

# ==================== Public API: UI ====================

func setup_banned_items_container(items_container: InventoryContainer) -> InventoryContainer:
	var banned_items_container = items_container.duplicate(15)
	banned_items_container.visible = false

	var parent = items_container.get_parent()
	parent.add_child(banned_items_container) # add so that the children are available
	parent.move_child(banned_items_container, items_container.get_index())

	var button_on_items = add_button(items_container, STR_SWITCH_TO_BANNED)
	var button_on_banned = add_button(banned_items_container, STR_SWITCH_TO_ITEMS)
	button_on_items.connect("pressed", self, "switch_container", [items_container, banned_items_container, button_on_banned])
	button_on_banned.connect("pressed", self, "switch_container", [items_container, banned_items_container, button_on_items])

	return banned_items_container


func add_button(items_container: InventoryContainer, text: String) -> Node:
	"""Add a toggle button to a container."""
	var toggle_button = MyMenuButton.new()
	toggle_button.text = text
	if RunData.is_coop_run:
		toggle_button.add_font_override("font", preload("res://resources/fonts/actual/base/font_22.tres"))
	else:
		toggle_button.add_font_override("font", preload("res://resources/fonts/actual/base/font_26.tres"))
	toggle_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	items_container._label.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var hbox = items_container._label.get_parent()
	hbox.add_child(toggle_button)
	hbox.move_child(toggle_button, 0)

	var sort_button = items_container.get_node("HBoxContainer/Sort_Inventory_button")
	toggle_button.focus_neighbour_right = sort_button.get_path()
	sort_button.focus_neighbour_left = toggle_button.get_path()

	return toggle_button


func switch_container(items_container: InventoryContainer, banned_items_container: InventoryContainer, next_button: MyMenuButton) -> void:
	if items_container.visible:
		items_container.visible = false
		banned_items_container.visible = true
		next_button.grab_focus()
	else:
		banned_items_container.visible = false
		items_container.visible = true
		next_button.grab_focus()


func set_banned_data(items_container: InventoryContainer, banned_data: Dictionary) -> void:
	items_container._label.text = STR_BANNED_ITEMS
	items_container._elements.clear_elements()
	for id in banned_data.keys():
		var item = get_item_by_id(id)
		var prevent_count = banned_data[id]
		items_container._elements.add_element_with_count(item, prevent_count, false, 0.5)

# ==================== Public API: Lifecycle ====================

func reset() -> void:
	"""
	Reset all data for a new run.

	Args:
		player_count: Number of players in the run
	"""
	if _all_items.size() == 0:
		_init_all_items()

	_init_nums()

	for player in _players:
		player.set_bannable_nums(_bannable_nums.duplicate(true))

	ModLoaderLog.info("Reset Bantato data for %d player(s)" % _players.size(), MOD_LOG)


func set_player_count(count: int, reset: = false) -> void :
	if reset:
		_players.clear()
	while _players.size() < count:
		var player_data = BantatoPlayerData.new({}, _bannable_nums.duplicate(true))
		_players.push_back(player_data)
	_players.resize(count)


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

	for player_index in range(data.size()):
		var banned_data = data[player_index]['banned_data']
		var bannable_nums = data[player_index]['bannable_nums']
		var player_data = BantatoPlayerData.new(banned_data, bannable_nums)
		
		_players.append(player_data)

	ModLoaderLog.info("Deserialized Bantato data for %d player(s)" % data.size(), MOD_LOG)


# ==================== Private Helpers ====================

func _is_valid_player_index(player_index: int) -> bool:
	"""Check if player_index is within valid bounds."""
	return player_index >= 0 and player_index < _players.size()
