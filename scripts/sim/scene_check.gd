extends SceneTree

# Loads scenes/table.tscn and reports success/failure, then quits.
func _initialize() -> void:
	await process_frame
	var ps := load("res://scenes/table.tscn")
	if ps == null:
		print("SCENE_LOAD_FAILED")
		quit(1)
		return
	var t: Node = ps.instantiate()
	if t == null:
		print("INSTANTIATE_FAILED")
		quit(1)
		return
	root.add_child(t)
	for i in 3:
		await process_frame
	print("SCENE_OK children=%d" % t.get_child_count())
	quit(0)
