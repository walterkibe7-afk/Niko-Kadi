extends SceneTree

# One-shot generator: writes res://assets/table/felt.png (720x1280).
# Green felt with woven grain + vignette, dark wood frame border.
# Run: Godot.exe --path <project> --script res://scripts/sim/gen_felt.gd

const W := 720
const H := 1280
const OUT := "res://assets/table/felt.png"
const BORDER := 34.0

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/table")

	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 20261124
	noise.frequency = 0.35
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var weave := FastNoiseLite.new()
	weave.seed = 7
	weave.frequency = 1.6

	var felt_base := Color(0.043, 0.235, 0.145)   # deep casino green
	var felt_light := Color(0.075, 0.31, 0.19)
	var wood_dark := Color(0.16, 0.085, 0.045)
	var wood_light := Color(0.34, 0.19, 0.10)

	for y in H:
		for x in W:
			var p := Vector2(x, y)
			# normalized pos for vignette
			var nx := (x / float(W) - 0.5) * 2.0
			var ny := (y / float(H) - 0.5) * 2.0
			var r := sqrt(nx * nx * 0.7 + ny * ny)

			var c: Color
			var d_edge := minf(minf(x, W - 1 - x), minf(y, H - 1 - y))
			if d_edge < BORDER:
				# Wood frame: grain runs along the nearest edge
				var along: float = (x if (d_edge == y or d_edge == H - 1 - y) else y) / 40.0
				var g := 0.5 + 0.5 * noise.get_noise_2d(along * 6.0, (d_edge if d_edge == y or d_edge == H - 1 - y else x) * 0.02)
				var ring := smoothstep(0.0, 3.0, d_edge)              # dark inner edge
				var lip := smoothstep(BORDER - 3.0, BORDER, d_edge)   # lighter lip toward felt
				c = wood_dark.lerp(wood_light, g * 0.55 + lip * 0.45)
				c = c.darkened((1.0 - ring) * 0.55)
			else:
				# Felt: base + fiber noise + cross weave + center light pool
				var n := noise.get_noise_2d(x * 0.9, y * 0.9) * 0.5 + 0.5
				var w := weave.get_noise_2d(x * 2.2, y * 2.2) * 0.5 + 0.5
				var fibers := n * 0.65 + w * 0.35
				c = felt_base.lerp(felt_light, fibers * 0.55)
				# light pool around center, then vignette to edges
				var pool := 1.0 - clampf(r * 0.75, 0.0, 1.0)
				c = c.lightened(pool * 0.16)
				c = c.darkened(clampf(r - 0.55, 0.0, 1.0) * 0.55)
				# subtle seam glow just inside the frame
				var seam := 1.0 - smoothstep(0.0, 10.0, d_edge - BORDER)
				c = c.lightened(seam * 0.06)

			img.set_pixel(x, y, c)

	var err := img.save_png(OUT)
	print("FELT_SAVED %s err=%d" % [OUT, err])
	quit(0 if err == OK else 1)
