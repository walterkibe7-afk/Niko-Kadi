class_name MainController
extends Node

const WELCOME_SCENE := preload("res://scenes/onboarding/welcome.tscn")
const TUTORIAL_SCENE := preload("res://scenes/onboarding/dashboard_tutorial.tscn")
const DASHBOARD_SCENE := preload("res://scenes/menu/dashboard.tscn")
const ARENA_SELECTION_SCENE := preload("res://scenes/menu/arena_selection.tscn")
const COLLECTION_SCENE := preload("res://scenes/menu/collection.tscn")
const PROFILE_SCENE := preload("res://scenes/menu/profile.tscn")
const GAME_PASS_SCENE := preload("res://scenes/menu/game_pass.tscn")
const TABLE_SCENE := preload("res://scenes/table.tscn")

var _active_scene: Node = null
var _active_overlay: Node = null


func _get_progression() -> Node:
	return get_node_or_null("/root/Progression")


func _ready() -> void:
	var prog := _get_progression()
	if prog != null and prog.onboarding_completed:
		_show_dashboard(not prog.tutorial_completed)
	else:
		_show_welcome()


func _show_welcome() -> void:
	_clear_active()
	var welcome := WELCOME_SCENE.instantiate() as WelcomeScreen
	welcome.welcome_completed.connect(_on_welcome_completed)
	add_child(welcome)
	_active_scene = welcome


func _on_welcome_completed(chosen_name: String) -> void:
	var prog := _get_progression()
	if prog != null:
		prog.complete_welcome(chosen_name)
		_show_dashboard(not prog.tutorial_completed)
	else:
		_show_dashboard(false)


func _show_dashboard(show_tutorial: bool) -> void:
	_clear_active()
	var dash := DASHBOARD_SCENE.instantiate() as Dashboard
	dash.play_requested.connect(_on_play_requested)
	dash.replay_tutorial_requested.connect(func() -> void: _open_tutorial(dash))
	dash.arena_selection_requested.connect(func() -> void: _open_sub_screen(ARENA_SELECTION_SCENE))
	dash.collection_requested.connect(func() -> void: _open_sub_screen(COLLECTION_SCENE))
	dash.profile_requested.connect(func() -> void: _open_sub_screen(PROFILE_SCENE))
	dash.game_pass_requested.connect(func() -> void: _open_sub_screen(GAME_PASS_SCENE))
	add_child(dash)
	_active_scene = dash

	if show_tutorial:
		_open_tutorial(dash)


func _open_tutorial(dash: Dashboard) -> void:
	if _active_overlay != null:
		return
	var tut := TUTORIAL_SCENE.instantiate() as DashboardTutorial
	add_child(tut)
	_active_overlay = tut
	tut.start_with_targets(dash.get_tutorial_targets())
	tut.tutorial_completed.connect(_finish_tutorial)
	tut.tutorial_skipped.connect(_finish_tutorial)


func _finish_tutorial() -> void:
	var prog := _get_progression()
	if prog != null:
		prog.tutorial_completed = true
		prog.save_progress()
	if _active_overlay != null:
		_active_overlay.queue_free()
		_active_overlay = null


func _on_play_requested(use_smart_bot: bool) -> void:
	_clear_active()
	var table := TABLE_SCENE.instantiate() as Table
	table.use_smart_bot = use_smart_bot
	table.match_finished.connect(_on_match_finished)
	table.exit_to_dashboard_requested.connect(func() -> void: _show_dashboard(false))
	add_child(table)

	var prog := _get_progression()
	var arena_id: String = "emerald_lounge"
	if prog != null:
		arena_id = prog.selected_arena_id
	var arena := CosmeticsCatalog.get_arena(arena_id)
	var bg := table.get_node_or_null("Background") as TextureRect
	if bg != null:
		bg.modulate = arena.primary_tint

	_active_scene = table


func _on_match_finished(player_won: bool) -> void:
	var prog := _get_progression()
	if prog != null:
		prog.record_match_result(player_won)


func _open_sub_screen(packed: PackedScene) -> void:
	_clear_active()
	var screen := packed.instantiate()
	if screen.has_signal("back_requested"):
		screen.back_requested.connect(func() -> void: _show_dashboard(false))
	add_child(screen)
	_active_scene = screen


func _clear_active() -> void:
	if _active_overlay != null:
		_active_overlay.queue_free()
		_active_overlay = null
	if _active_scene != null:
		_active_scene.queue_free()
		_active_scene = null
