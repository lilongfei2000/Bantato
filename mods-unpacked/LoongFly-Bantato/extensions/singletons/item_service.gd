extends "res://singletons/item_service.gd"

# Access BantatoService
onready var BantatoService = get_node("/root/ModLoader/LoongFly-Bantato/BantatoService")

# Hook _get_rand_item_for_wave to filter out Bantato-banned items
func _get_rand_item_for_wave(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> ItemParentData:
	bantato_get_rand_item_retry(wave, player_index, type, args)


func bantato_get_item_by_id(id):
	if is_weapon_id(id):
		return get_weapon_from_weapon_id(id)
	return get_item_from_id(id)


# ==================== Method A: Simple Retry Approach ====================
# Picks item, checks if banned, retries if needed
# Increments prevent_count for each individual banned item encounter
# More expensive than incremental approach due to full logic re-execution per retry

func bantato_get_rand_item_retry(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> ItemParentData:
	var player_character = RunData.get_player_character(player_index)
	var rand_wanted = randf()
	var item_tier = get_tier_from_wave(wave, player_index, args.increase_tier)

	if args.fixed_tier != -1:
		item_tier = args.fixed_tier

	if type == TierData.WEAPONS:
		var min_weapon_tier = RunData.get_player_effect("min_weapon_tier", player_index)
		var max_weapon_tier = RunData.get_player_effect("max_weapon_tier", player_index)
		item_tier = clamp(item_tier, min_weapon_tier, max_weapon_tier)

	var banned_items = RunData.players_data[player_index].banned_items
	var pool = get_pool(item_tier, type)
	var backup_pool = get_pool(item_tier, type)
	var items_to_remove = []

	if banned_items.size() > 0:
		for item_id in banned_items:
			pool = remove_element_by_id(pool, item_id)
			backup_pool = remove_element_by_id(backup_pool, item_id)

	
	for shop_item in args.excluded_items:
		pool = remove_element_by_id_with_item(pool, shop_item[0])
		backup_pool = remove_element_by_id_with_item(backup_pool, shop_item[0])

	if type == TierData.WEAPONS:
		var bonus_chance_same_weapon_set = max(0, (MAX_WAVE_ONE_WEAPON_GUARANTEED + 1 - RunData.current_wave) * (BONUS_CHANCE_SAME_WEAPON_SET / MAX_WAVE_ONE_WEAPON_GUARANTEED))
		var chance_same_weapon_set = CHANCE_SAME_WEAPON_SET + bonus_chance_same_weapon_set
		var bonus_chance_same_weapon = max(0, (MAX_WAVE_ONE_WEAPON_GUARANTEED + 1 - RunData.current_wave) * (BONUS_CHANCE_SAME_WEAPON / MAX_WAVE_ONE_WEAPON_GUARANTEED))
		var chance_same_weapon = CHANCE_SAME_WEAPON + bonus_chance_same_weapon

		var no_melee_weapons: bool = RunData.get_player_effect_bool("no_melee_weapons", player_index)
		var no_ranged_weapons: bool = RunData.get_player_effect_bool("no_ranged_weapons", player_index)
		var no_duplicate_weapons: bool = RunData.get_player_effect_bool("no_duplicate_weapons", player_index)
		var no_structures: bool = RunData.get_player_effect("remove_shop_items", player_index).has("structure")

		var player_sets: Array = RunData.get_player_sets(player_index)
		var unique_weapon_ids: Dictionary = RunData.get_unique_weapon_ids(player_index)

		for item in pool:
			if no_melee_weapons and item.type == WeaponType.MELEE:
				backup_pool = remove_element_by_id_with_item(backup_pool, item)
				items_to_remove.push_back(item)
				continue

			if no_ranged_weapons and item.type == WeaponType.RANGED:
				backup_pool = remove_element_by_id_with_item(backup_pool, item)
				items_to_remove.push_back(item)
				continue

			if no_duplicate_weapons:
				for weapon in unique_weapon_ids.values():
					
					if item.weapon_id == weapon.weapon_id and item.tier < weapon.tier:
						backup_pool = remove_element_by_id_with_item(backup_pool, item)
						items_to_remove.push_back(item)
						break

					
					elif item.my_id == weapon.my_id and weapon.upgrades_into == null:
						backup_pool = remove_element_by_id_with_item(backup_pool, item)
						items_to_remove.push_back(item)
						break

			if no_structures and EntityService.is_weapon_spawning_structure(item):
				backup_pool = remove_element_by_id_with_item(backup_pool, item)
				items_to_remove.append(item)

			if rand_wanted < chance_same_weapon:
				if not item.weapon_id in unique_weapon_ids:
					items_to_remove.push_back(item)
					continue

			elif rand_wanted < chance_same_weapon_set:
				var remove: = true
				for set in item.sets:
					if set.my_id in player_sets:
						remove = false
				if remove:
					items_to_remove.push_back(item)
					continue

	elif type == TierData.ITEMS:
		if Utils.get_chance_success(CHANCE_WANTED_ITEM_TAG) and player_character.wanted_tags.size() > 0:
			for item in pool:
				var has_wanted_tag = false

				for tag in item.tags:
					if player_character.wanted_tags.has(tag):
						has_wanted_tag = true
						break

				if not has_wanted_tag:
					items_to_remove.push_back(item)

		var remove_item_tags: Array = RunData.get_player_effect("remove_shop_items", player_index)
		for tag_to_remove in remove_item_tags:
			for item in pool:
				if tag_to_remove in item.tags:
					items_to_remove.append(item)

		if RunData.current_wave < RunData.nb_of_waves:
			if player_character.banned_item_groups.size() > 0:
				for banned_item_group in player_character.banned_item_groups:

					if not banned_item_group in item_groups:
						print(str(banned_item_group) + " does not exist in ItemService.item_groups")
						continue

					for item in pool:
						if item_groups[banned_item_group].has(item.my_id):
							items_to_remove.append(item)

			if player_character.banned_items.size() > 0:
				for item in pool:
					if player_character.banned_items.has(item.my_id):
						items_to_remove.append(item)
		else:
			
			for item in pool:
				if banned_items_for_endless.has(item.my_id):
					items_to_remove.append(item)

	var limited_items = get_limited_items(args.owned_and_shop_items)

	for key in limited_items:
		if limited_items[key][1] >= limited_items[key][0].max_nb:
			backup_pool = remove_element_by_id_with_item(backup_pool, limited_items[key][0])
			items_to_remove.push_back(limited_items[key][0])

	for item in items_to_remove:
		pool = remove_element_by_id_with_item(pool, item)

	# Retry loop: pick item, check if banned by Bantato, remove and retry if needed
	var elt
	while true:
		var current_pool = pool
		
		if pool.size() == 0:
			current_pool = backup_pool
		
		# Pick random item
		elt = Utils.get_rand_element(current_pool)
		
		# Check if banned by Bantato
		if BantatoService.is_item_banned(elt, player_index):
			# Increment prevent counter
			BantatoService.increment_prevent_count(elt.my_id, player_index)
			continue
		
		# Item is not banned, apply special handling and return
		if elt.my_id == "item_axolotl" and randf() < 0.5:
			continue
		
		if DebugService.force_item_in_shop != "" and randf() < 0.5:
			elt = get_element(items, DebugService.force_item_in_shop)
			if elt == null:
				elt = get_element(weapons, DebugService.force_item_in_shop)
		
		if elt != null and elt.my_id == "item_axolotl" and elt.effects.size() > 0 and "stats_swapped" in elt.effects[0]:
			elt.effects[0].stats_swapped = []

		break
		
	return apply_item_effect_modifications(elt, player_index)


# ==================== Method B: Incremental Removal Approach ====================
# Hybrid approach: picks item, checks if banned, removes and retries if needed
# Increments prevent_count for each individual banned item encounter
# More efficient than retry approach (Method A) - only filters once upfront

func bantato_get_rand_item_incremental(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> ItemParentData:
	var player_character = RunData.get_player_character(player_index)
	var rand_wanted = randf()
	var item_tier = get_tier_from_wave(wave, player_index, args.increase_tier)

	if args.fixed_tier != -1:
		item_tier = args.fixed_tier

	if type == TierData.WEAPONS:
		var min_weapon_tier = RunData.get_player_effect("min_weapon_tier", player_index)
		var max_weapon_tier = RunData.get_player_effect("max_weapon_tier", player_index)
		item_tier = clamp(item_tier, min_weapon_tier, max_weapon_tier)

	# Get base pool and create working copy
	var pool = get_pool(item_tier, type)
	var backup_pool = get_pool(item_tier, type)
	var items_to_remove = []

	# Apply game logic filters (same as original _get_rand_item_for_wave)
	
	if type == TierData.WEAPONS:
		var bonus_chance_same_weapon_set = max(0, (MAX_WAVE_ONE_WEAPON_GUARANTEED + 1 - RunData.current_wave) * (BONUS_CHANCE_SAME_WEAPON_SET / MAX_WAVE_ONE_WEAPON_GUARANTEED))
		var chance_same_weapon_set = CHANCE_SAME_WEAPON_SET + bonus_chance_same_weapon_set
		var bonus_chance_same_weapon = max(0, (MAX_WAVE_ONE_WEAPON_GUARANTEED + 1 - RunData.current_wave) * (BONUS_CHANCE_SAME_WEAPON / MAX_WAVE_ONE_WEAPON_GUARANTEED))
		var chance_same_weapon = CHANCE_SAME_WEAPON + bonus_chance_same_weapon

		var no_melee_weapons: bool = RunData.get_player_effect_bool("no_melee_weapons", player_index)
		var no_ranged_weapons: bool = RunData.get_player_effect_bool("no_ranged_weapons", player_index)
		var no_duplicate_weapons: bool = RunData.get_player_effect_bool("no_duplicate_weapons", player_index)
		var no_structures: bool = RunData.get_player_effect("remove_shop_items", player_index).has("structure")

		var player_sets: Array = RunData.get_player_sets(player_index)
		var unique_weapon_ids: Dictionary = RunData.get_unique_weapon_ids(player_index)

		for item in pool:
			if no_melee_weapons and item.type == WeaponType.MELEE:
				backup_pool = remove_element_by_id_with_item(backup_pool, item)
				items_to_remove.push_back(item)
				continue

			if no_ranged_weapons and item.type == WeaponType.RANGED:
				backup_pool = remove_element_by_id_with_item(backup_pool, item)
				items_to_remove.push_back(item)
				continue

			if no_duplicate_weapons:
				for weapon in unique_weapon_ids.values():
					
					if item.weapon_id == weapon.weapon_id and item.tier < weapon.tier:
						backup_pool = remove_element_by_id_with_item(backup_pool, item)
						items_to_remove.push_back(item)
						break

					
					elif item.my_id == weapon.my_id and weapon.upgrades_into == null:
						backup_pool = remove_element_by_id_with_item(backup_pool, item)
						items_to_remove.push_back(item)
						break

			if no_structures and EntityService.is_weapon_spawning_structure(item):
				backup_pool = remove_element_by_id_with_item(backup_pool, item)
				items_to_remove.append(item)

			if rand_wanted < chance_same_weapon:
				if not item.weapon_id in unique_weapon_ids:
					items_to_remove.push_back(item)
					continue

			elif rand_wanted < chance_same_weapon_set:
				var remove: = true
				for set in item.sets:
					if set.my_id in player_sets:
						remove = false
				if remove:
					items_to_remove.push_back(item)
					continue

	elif type == TierData.ITEMS:
		if Utils.get_chance_success(CHANCE_WANTED_ITEM_TAG) and player_character.wanted_tags.size() > 0:
			for item in pool:
				var has_wanted_tag = false

				for tag in item.tags:
					if player_character.wanted_tags.has(tag):
						has_wanted_tag = true
						break

				if not has_wanted_tag:
					items_to_remove.push_back(item)

		var remove_item_tags: Array = RunData.get_player_effect("remove_shop_items", player_index)
		for tag_to_remove in remove_item_tags:
			for item in pool:
				if tag_to_remove in item.tags:
					items_to_remove.append(item)

		if RunData.current_wave < RunData.nb_of_waves:
			if player_character.banned_item_groups.size() > 0:
				for banned_item_group in player_character.banned_item_groups:

					if not banned_item_group in item_groups:
						print(str(banned_item_group) + " does not exist in ItemService.item_groups")
						continue

					for item in pool:
						if item_groups[banned_item_group].has(item.my_id):
							items_to_remove.append(item)

			if player_character.banned_items.size() > 0:
				for item in pool:
					if player_character.banned_items.has(item.my_id):
						items_to_remove.append(item)
		else:
			
			for item in pool:
				if banned_items_for_endless.has(item.my_id):
					items_to_remove.append(item)

	var limited_items = get_limited_items(args.owned_and_shop_items)

	for key in limited_items:
		if limited_items[key][1] >= limited_items[key][0].max_nb:
			backup_pool = remove_element_by_id_with_item(backup_pool, limited_items[key][0])
			items_to_remove.push_back(limited_items[key][0])

	for item in items_to_remove:
		pool = remove_element_by_id_with_item(pool, item)

	# Apply exclusions from args
	for shop_item in args.excluded_items:
		pool = remove_element_by_id_with_item(pool, shop_item[0])
		backup_pool = remove_element_by_id_with_item(backup_pool, shop_item[0])

	# Incremental loop: pick item, check banned, remove and retry if needed
	while pool.size() > 0 or backup_pool.size() > 0:
		var elt
		var current_pool = pool
		
		if pool.size() == 0:
			current_pool = backup_pool
		
		# Pick random item
		elt = Utils.get_rand_element(current_pool)
		
		# Check if banned by Bantato
		if BantatoService.is_item_banned(elt, player_index):
			# Increment prevent counter
			BantatoService.increment_prevent_count(elt.my_id, player_index)
			# Remove from pools
			pool = remove_element_by_id_with_item(pool, elt)
			backup_pool = remove_element_by_id_with_item(backup_pool, elt)
			# Continue loop to retry
			continue
		
		# Item is not banned, apply special handling and return
		if elt.my_id == "item_axolotl" and randf() < 0.5:
			continue
		
		if DebugService.force_item_in_shop != "" and randf() < 0.5:
			elt = get_element(items, DebugService.force_item_in_shop)
			if elt == null:
				elt = get_element(weapons, DebugService.force_item_in_shop)
		
		if elt != null and elt.my_id == "item_axolotl" and elt.effects.size() > 0 and "stats_swapped" in elt.effects[0]:
			elt.effects[0].stats_swapped = []
		
		return apply_item_effect_modifications(elt, player_index)
	
	# Fallback if both pools empty
	return Utils.get_rand_element(_tiers_data[item_tier][type])
