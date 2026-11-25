class_name PlayerProgress
extends Node

signal profile_changed
signal coins_changed(new_balance: int)
signal onboarding_changed(completed: bool)
signal cosmetics_changed
signal pass_changed

const SAVE_PATH := "user://kadi_player_progress.cfg"
const XP_PER_TIER := 100

var player_name: String = "Player"
var onboarding_completed: bool = false
var tutorial_completed: bool = false
var coins: int = 250
var season_xp: int = 0
var season_level: int = 1
var claimed_pass_tiers: PackedInt32Array = PackedInt32Array()

var matches_played: int = 0
var matches_won: int = 0

var selected_deck_id: String = "royal_emerald"
var selected_arena_id: String = "emerald_lounge"
var unlocked_deck_ids: PackedStringArray = PackedStringArray(["royal_emerald"])
var unlocked_arena_ids: PackedStringArray = PackedStringArray(["emerald_lounge"])


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	player_name = str(cfg.get_value("profile", "player_name", "Player"))
	onboarding_completed = bool(cfg.get_value("onboarding", "welcome_completed", false))
	tutorial_completed = bool(cfg.get_value("onboarding", "tutorial_completed", false))
	coins = int(cfg.get_value("economy", "coins", 250))
	season_xp = int(cfg.get_value("pass", "season_xp", 0))
	season_level = int(cfg.get_value("pass", "season_level", 1))
	claimed_pass_tiers = cfg.get_value("pass", "claimed_tiers", PackedInt32Array())
	matches_played = int(cfg.get_value("stats", "matches_played", 0))
	matches_won = int(cfg.get_value("stats", "matches_won", 0))
	selected_deck_id = str(cfg.get_value("cosmetics", "selected_deck_id", "royal_emerald"))
	selected_arena_id = str(cfg.get_value("cosmetics", "selected_arena_id", "emerald_lounge"))
	unlocked_deck_ids = cfg.get_value("cosmetics", "unlocked_deck_ids", PackedStringArray(["royal_emerald"]))
	unlocked_arena_ids = cfg.get_value("cosmetics", "unlocked_arena_ids", PackedStringArray(["emerald_lounge"]))


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("profile", "player_name", player_name)
	cfg.set_value("onboarding", "welcome_completed", onboarding_completed)
	cfg.set_value("onboarding", "tutorial_completed", tutorial_completed)
	cfg.set_value("economy", "coins", coins)
	cfg.set_value("pass", "season_xp", season_xp)
	cfg.set_value("pass", "season_level", season_level)
	cfg.set_value("pass", "claimed_tiers", claimed_pass_tiers)
	cfg.set_value("stats", "matches_played", matches_played)
	cfg.set_value("stats", "matches_won", matches_won)
	cfg.set_value("cosmetics", "selected_deck_id", selected_deck_id)
	cfg.set_value("cosmetics", "selected_arena_id", selected_arena_id)
	cfg.set_value("cosmetics", "unlocked_deck_ids", unlocked_deck_ids)
	cfg.set_value("cosmetics", "unlocked_arena_ids", unlocked_arena_ids)
	cfg.save(SAVE_PATH)


func set_player_name(new_name: String) -> void:
	var trimmed := new_name.strip_edges()
	if trimmed.is_empty():
		return
	player_name = trimmed
	save_progress()
	profile_changed.emit()


func complete_welcome(chosen_name: String) -> void:
	var trimmed := chosen_name.strip_edges()
	if not trimmed.is_empty():
		player_name = trimmed
	onboarding_completed = true
	save_progress()
	onboarding_changed.emit(true)
	profile_changed.emit()


func add_coins(amount: int) -> void:
	if amount == 0:
		return
	coins = maxi(0, coins + amount)
	save_progress()
	coins_changed.emit(coins)


func record_match_result(player_won: bool) -> void:
	matches_played += 1
	if player_won:
		matches_won += 1
	coins += 50 if player_won else 15
	season_xp += 45 if player_won else 20
	season_level = 1 + int(season_xp / XP_PER_TIER)
	save_progress()
	coins_changed.emit(coins)
	pass_changed.emit()
	profile_changed.emit()


func is_deck_unlocked(deck_id: String) -> bool:
	return deck_id in unlocked_deck_ids


func is_arena_unlocked(arena_id: String) -> bool:
	return arena_id in unlocked_arena_ids


func unlock_and_select_deck(deck: DeckSkinData) -> bool:
	if is_deck_unlocked(deck.id):
		selected_deck_id = deck.id
		save_progress()
		cosmetics_changed.emit()
		profile_changed.emit()
		return true
	if coins < deck.unlock_cost:
		return false
	coins -= deck.unlock_cost
	unlocked_deck_ids.append(deck.id)
	selected_deck_id = deck.id
	save_progress()
	coins_changed.emit(coins)
	cosmetics_changed.emit()
	profile_changed.emit()
	return true


func unlock_and_select_arena(arena: ArenaThemeData) -> bool:
	if is_arena_unlocked(arena.id):
		selected_arena_id = arena.id
		save_progress()
		cosmetics_changed.emit()
		profile_changed.emit()
		return true
	if coins < arena.unlock_cost:
		return false
	coins -= arena.unlock_cost
	unlocked_arena_ids.append(arena.id)
	selected_arena_id = arena.id
	save_progress()
	coins_changed.emit(coins)
	cosmetics_changed.emit()
	profile_changed.emit()
	return true


func is_tier_claimed(tier: int) -> bool:
	return tier in claimed_pass_tiers


func can_claim_tier(tier: int) -> bool:
	return season_level >= tier and not is_tier_claimed(tier)


func claim_pass_tier(tier: int, reward_coins: int) -> bool:
	if not can_claim_tier(tier):
		return false
	claimed_pass_tiers.append(tier)
	coins += reward_coins
	save_progress()
	coins_changed.emit(coins)
	pass_changed.emit()
	return true
