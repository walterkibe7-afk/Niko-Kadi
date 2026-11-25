class_name CosmeticsCatalog
extends RefCounted


static func get_decks() -> Array[DeckSkinData]:
	var decks: Array[DeckSkinData] = []

	var royal := DeckSkinData.new()
	royal.id = "royal_emerald"
	royal.display_name = "Royal Emerald"
	royal.description = "Ivory card faces framed in brushed gold with deep emerald backs."
	royal.face_bg_color = Color(0.97, 0.95, 0.89, 1.0)
	royal.face_accent_color = Color(0.85, 0.70, 0.35, 1.0)
	royal.back_primary_color = Color(0.03, 0.18, 0.11, 1.0)
	royal.unlock_cost = 0
	decks.append(royal)

	var obsidian := DeckSkinData.new()
	obsidian.id = "obsidian_gold"
	obsidian.display_name = "Obsidian Gold"
	obsidian.description = "Midnight onyx backs paired with warm champagne card faces."
	obsidian.face_bg_color = Color(0.95, 0.92, 0.84, 1.0)
	obsidian.face_accent_color = Color(0.96, 0.80, 0.34, 1.0)
	obsidian.back_primary_color = Color(0.06, 0.07, 0.09, 1.0)
	obsidian.unlock_cost = 150
	decks.append(obsidian)

	var velvet := DeckSkinData.new()
	velvet.id = "crimson_velvet"
	velvet.display_name = "Crimson Velvet"
	velvet.description = "Rich burgundy backs with antique brass face trim."
	velvet.face_bg_color = Color(0.98, 0.95, 0.91, 1.0)
	velvet.face_accent_color = Color(0.88, 0.64, 0.30, 1.0)
	velvet.back_primary_color = Color(0.28, 0.04, 0.07, 1.0)
	velvet.unlock_cost = 300
	decks.append(velvet)

	var sapphire := DeckSkinData.new()
	sapphire.id = "sapphire_mirage"
	sapphire.display_name = "Sapphire Mirage"
	sapphire.description = "Deep indigo backs with gilded silver-gold borders."
	sapphire.face_bg_color = Color(0.95, 0.96, 0.98, 1.0)
	sapphire.face_accent_color = Color(0.82, 0.74, 0.44, 1.0)
	sapphire.back_primary_color = Color(0.05, 0.12, 0.28, 1.0)
	sapphire.unlock_cost = 450
	decks.append(sapphire)

	return decks


static func get_deck(deck_id: String) -> DeckSkinData:
	var list := get_decks()
	for d in list:
		if d.id == deck_id:
			return d
	return list[0]


static func get_arenas() -> Array[ArenaThemeData]:
	var arenas: Array[ArenaThemeData] = []

	var lounge := ArenaThemeData.new()
	lounge.id = "emerald_lounge"
	lounge.display_name = "Emerald Lounge"
	lounge.description = "Signature deep emerald felt with refined gold trim."
	lounge.primary_tint = Color(1.0, 1.0, 1.0, 1.0)
	lounge.vignette_color = Color(0.01, 0.05, 0.03, 0.56)
	lounge.accent_gold = Color(0.93, 0.78, 0.32, 1.0)
	lounge.unlock_cost = 0
	arenas.append(lounge)

	var midnight := ArenaThemeData.new()
	midnight.id = "midnight_parlor"
	midnight.display_name = "Midnight Parlor"
	midnight.description = "Moody slate-teal felt built for high-stakes late-night Kadi."
	midnight.primary_tint = Color(0.62, 0.85, 0.92, 1.0)
	midnight.vignette_color = Color(0.02, 0.04, 0.08, 0.64)
	midnight.accent_gold = Color(0.95, 0.82, 0.44, 1.0)
	midnight.unlock_cost = 200
	arenas.append(midnight)

	var royal_hall := ArenaThemeData.new()
	royal_hall.id = "crimson_club"
	royal_hall.display_name = "Crimson Club"
	royal_hall.description = "Warm mahogany-crimson felt with gilded brass highlights."
	royal_hall.primary_tint = Color(1.0, 0.56, 0.52, 1.0)
	royal_hall.vignette_color = Color(0.08, 0.02, 0.02, 0.60)
	royal_hall.accent_gold = Color(0.96, 0.78, 0.34, 1.0)
	royal_hall.unlock_cost = 350
	arenas.append(royal_hall)

	var imperial := ArenaThemeData.new()
	imperial.id = "imperial_jade"
	imperial.display_name = "Imperial Jade"
	imperial.description = "Luminous jade tournament baize reserved for seasoned players."
	imperial.primary_tint = Color(0.75, 1.0, 0.82, 1.0)
	imperial.vignette_color = Color(0.01, 0.06, 0.04, 0.50)
	imperial.accent_gold = Color(0.98, 0.86, 0.42, 1.0)
	imperial.unlock_cost = 500
	arenas.append(imperial)

	return arenas


static func get_arena(arena_id: String) -> ArenaThemeData:
	var list := get_arenas()
	for a in list:
		if a.id == arena_id:
			return a
	return list[0]


static func get_pass_tiers() -> Array[Dictionary]:
	return [
		{"tier": 1, "title": "Starter Pouch", "reward_type": "coins", "amount": 50, "label": "+50 Coins"},
		{"tier": 2, "title": "Emerald Reserve", "reward_type": "coins", "amount": 75, "label": "+75 Coins"},
		{"tier": 3, "title": "Dealer's Cut", "reward_type": "coins", "amount": 100, "label": "+100 Coins"},
		{"tier": 4, "title": "Niko Kadi Bonus", "reward_type": "coins", "amount": 150, "label": "+150 Coins"},
		{"tier": 5, "title": "Grand Lounge Jackpot", "reward_type": "coins", "amount": 250, "label": "+250 Coins"},
	]


static func get_achievements(matches_played: int, matches_won: int, unlocked_decks: int, unlocked_arenas: int) -> Array[Dictionary]:
	return [
		{
			"id": "first_deal",
			"title": "First Deal",
			"description": "Complete your first Kadi match.",
			"unlocked": matches_played >= 1,
		},
		{
			"id": "first_victory",
			"title": "Table Victor",
			"description": "Win your first match against the bot.",
			"unlocked": matches_won >= 1,
		},
		{
			"id": "five_wins",
			"title": "Card Shark",
			"description": "Win 5 Kadi matches.",
			"unlocked": matches_won >= 5,
		},
		{
			"id": "collector",
			"title": "Deck Collector",
			"description": "Unlock at least 2 complete card-deck skins.",
			"unlocked": unlocked_decks >= 2,
		},
		{
			"id": "high_roller",
			"title": "Venue Regular",
			"description": "Unlock at least 2 themed arenas.",
			"unlocked": unlocked_arenas >= 2,
		},
	]
