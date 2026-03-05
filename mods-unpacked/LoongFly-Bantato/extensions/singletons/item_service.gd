extends "res://singletons/item_service.gd"

# Access BantatoService
onready var BantatoService = get_node("/root/ModLoader/LoongFly-Bantato/BantatoService")

# Hook _get_rand_item_for_wave to filter out Bantato-banned items
func _get_rand_item_for_wave(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> ItemParentData:
	var pools = bantato_get_rand_item_pool(wave, player_index, type, args)
	var pool = pools[0] if pools[0].size() > 0 else pools[1]
	
	var elt = BantatoService.get_rand_item_retry(pool, player_index)

	while elt.my_id_hash == Keys.item_axolotl_hash and randf() < 0.5:
		elt = BantatoService.get_rand_item_retry(pool, player_index)

	if DebugService.force_item_in_shop != "" and randf() < 0.5:
		elt = get_element(items, Keys.generate_hash(DebugService.force_item_in_shop))
		if elt == null:
			elt = get_element(weapons, Keys.generate_hash(DebugService.force_item_in_shop))

	
	if elt.my_id_hash == Keys.item_axolotl_hash and elt.effects.size() > 0 and Keys.stats_swapped_hash in elt.effects[0]:
		elt.effects[0][Keys.stats_swapped_hash] = []

	return apply_item_effect_modifications(elt, player_index)


func bantato_get_rand_item_pool(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> Array:
	var player_character = RunData.get_player_character(player_index)
	var rand_wanted = randf()
	var item_tier = get_tier_from_wave(wave, player_index, args.increase_tier)

	if args.fixed_tier != - 1:
		item_tier = args.fixed_tier

	if type == TierData.WEAPONS:
		var min_weapon_tier = RunData.get_player_effect(Keys.min_weapon_tier_hash, player_index)
		var max_weapon_tier = RunData.get_player_effect(Keys.max_weapon_tier_hash, player_index)
		item_tier = clamp(item_tier, min_weapon_tier, max_weapon_tier)

	var banned_items = RunData.players_data[player_index].banned_items
	var pool = get_pool(item_tier, type)
	var backup_pool = get_pool(item_tier, type)
	var items_to_remove = []

	if banned_items.size() > 0:
		for item_id in banned_items:
			if item_id is String:
				var item_id_hash = Keys.generate_hash(item_id)
				pool = remove_element_by_id(pool, item_id_hash)
				backup_pool = remove_element_by_id(backup_pool, item_id_hash)
			else:
				pool = remove_element_by_id(pool, item_id)
				backup_pool = remove_element_by_id(backup_pool, item_id)


	
	for shop_item in args.excluded_items:
		pool = remove_element_by_id_with_item(pool, shop_item[0])
		backup_pool = remove_element_by_id_with_item(pool, shop_item[0])

	if type == TierData.WEAPONS:
		var bonus_chance_same_weapon_set = max(0, (MAX_WAVE_ONE_WEAPON_GUARANTEED + 1 - RunData.current_wave) * (BONUS_CHANCE_SAME_WEAPON_SET / MAX_WAVE_ONE_WEAPON_GUARANTEED))
		var chance_same_weapon_set = CHANCE_SAME_WEAPON_SET + bonus_chance_same_weapon_set
		var bonus_chance_same_weapon = max(0, (MAX_WAVE_ONE_WEAPON_GUARANTEED + 1 - RunData.current_wave) * (BONUS_CHANCE_SAME_WEAPON / MAX_WAVE_ONE_WEAPON_GUARANTEED))
		var chance_same_weapon = CHANCE_SAME_WEAPON + bonus_chance_same_weapon

		var no_melee_weapons: bool = RunData.get_player_effect_bool(Keys.no_melee_weapons_hash, player_index)
		var no_ranged_weapons: bool = RunData.get_player_effect_bool(Keys.no_ranged_weapons_hash, player_index)
		var no_duplicate_weapons: bool = RunData.get_player_effect_bool(Keys.no_duplicate_weapons_hash, player_index)
		var no_structures: bool = RunData.get_player_effect(Keys.remove_shop_items_hash, player_index).has(Keys.structure_hash)

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
					
					if item.weapon_id_hash == weapon.weapon_id_hash and item.tier < weapon.tier:
						backup_pool = remove_element_by_id_with_item(backup_pool, item)
						items_to_remove.push_back(item)
						break

					
					elif item.my_id_hash == weapon.my_id_hash and weapon.upgrades_into == null:
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
					if set.my_id_hash in player_sets:
						remove = false
				if remove:
					items_to_remove.push_back(item)
					continue

	elif type == TierData.ITEMS:
		var wanted_item_tag_chance = CHANCE_WANTED_ITEM_TAG
		if RunData.get_player_effects(player_index).has(Keys.stat_boosted_wanted_item_tag_hash) and RunData.get_player_effect_bool(Keys.stat_boosted_wanted_item_tag_hash, player_index):
			wanted_item_tag_chance = BOOSTED_WANTED_ITEM_TAG
		if Utils.get_chance_success(wanted_item_tag_chance) and player_character.wanted_tags.size() > 0:
			for item in pool:
				var has_wanted_tag = false

				for tag in item.tags:
					if player_character.wanted_tags.has(tag):
						has_wanted_tag = true
						break

				if not has_wanted_tag:
					items_to_remove.push_back(item)

		if args.forced_shop_tag != null:
			for item in pool:
				if not items_to_remove.has(item) and not item.tags.has(args.forced_shop_tag):
					items_to_remove.push_back(item)

		var remove_item_tags: Array = RunData.get_player_effect(Keys.remove_shop_items_hash, player_index)

		for tag_to_remove in remove_item_tags:
			for item in pool:
				if Keys.hash_to_string[tag_to_remove] in item.tags:
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
				if banned_items_for_endless.has(item.my_id_hash):
					items_to_remove.append(item)

	var limited_items = get_limited_items(args.owned_and_shop_items)

	for key in limited_items:
		if limited_items[key][1] >= limited_items[key][0].max_nb:
			backup_pool = remove_element_by_id_with_item(backup_pool, limited_items[key][0])
			items_to_remove.push_back(limited_items[key][0])

	for item in items_to_remove:
		pool = remove_element_by_id_with_item(pool, item)

	return [pool, backup_pool]
