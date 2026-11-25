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

	var felt_base := Color(0.038, 0.20, 0.125)   # deep luxury emerald baize
	var felt_light := Color(0.065, 0.28, 0.175)
	var wood_dark := Color(0.12, 0.06, 0.03)     # polished dark walnut
	var wood_light := Color(0.28, 0.15, 0.08)
	var gold_inlay := Color(0.88, 0.74, 0.36)    # metallic antique gold

	var center := Vector2(W * 0.5, H * 0.5)

	for y in H:
		for x in W:
			var p := Vector2(x, y)
			# normalized pos for vignette
			var nx := (x / float(W) - 0.5) * 2.0
			var ny := (y / float(H) - 0.5) * 2.0
			var r := sqrt(nx * nx * 0.72 + ny * ny)

			var c: Color
			var d_edge := minf(minf(x, W - 1 - x), minf(y, H - 1 - y))
			if d_edge < BORDER:
				# Wood frame: grain runs along the nearest edge
				var along: float = (x if (d_edge == y or d_edge == H - 1 - y) else y) / 36.0
				var g := 0.5 + 0.5 * noise.get_noise_2d(along * 7.0, (d_edge if d_edge == y or d_edge == H - 1 - y else x) * 0.03)
				var ring := smoothstep(0.0, 4.0, d_edge)              # dark bevel inner edge
				var lip := smoothstep(BORDER - 3.0, BORDER, d_edge)   # cushion bevel
				c = wood_dark.lerp(wood_light, g * 0.6 + lip * 0.4)
				c = c.darkened((1.0 - ring) * 0.6)
			elif d_edge < BORDER + 3.0:
				# Gold pinstripe inlay channel between wood rail and felt
				var t := (d_edge - BORDER) / 3.0
				var gold_noise := 0.85 + 0.15 * noise.get_noise_2d(x * 0.1, y * 0.1)
				c = gold_inlay * gold_noise
				if t < 0.3:
					c = c.darkened(0.4) # groove shadow
				elif t > 0.7:
					c = c.lightened(0.2) # bevel highlight
			else:
				# Felt: base + fine fiber noise + cross weave + center pool lighting
				var n := noise.get_noise_2d(x * 1.2, y * 1.2) * 0.5 + 0.5
				var w := weave.get_noise_2d(x * 2.6, y * 2.6) * 0.5 + 0.5
				var fibers := n * 0.6 + w * 0.4
				c = felt_base.lerp(felt_light, fibers * 0.5)

				# Warm light pool around center, then gradual vignette to edges
				var pool := 1.0 - clampf(r * 0.7, 0.0, 1.0)
				c = c.lightened(pool * 0.22)
				c = c.darkened(clampf(r - 0.5, 0.0, 1.0) * 0.5)

				# Subtle elegant table watermark circle in center area
				var dist_center := p.distance_to(center)
				var ring1 := absf(dist_center - 190.0)
				var ring2 := absf(dist_center - 184.0)
				if ring1 < 1.5:
					c = c.lightened((1.5 - ring1) * 0.09)
				elif ring2 < 0.8:
					c = c.lightened((0.8 - ring2) * 0.06)

			img.set_pixel(x, y, c)

	var err := img.save_png(OUT)
	print("FELT_SAVED %s err=%d" % [OUT, err])
	quit(0 if err == OK else 1)
