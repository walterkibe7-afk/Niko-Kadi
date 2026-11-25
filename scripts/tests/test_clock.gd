extends SceneTree

# Headless chess-clock unit tests using fake (deterministic) now_ms values.
# Covers: normal turn, lag credit, flagging, credit never making remaining negative.

const START_MS := 600_000

var _failed := false

func _init() -> void:
	await _run()

func _ok(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		_failed = true
		print("FAIL: %s" % label)

func _run() -> void:
	print("=== CLOCK TESTS (headless, fake now_ms) ===")

	# ---- Normal turn: player 0 starts, time elapses, stops ----
	var clock := ChessClock.new()
	var t0 := 1_000_000  # fake now_ms when turn starts
	clock.start(0, t0)
	_ok(clock.running_player == 0, "start sets running_player")
	_ok(clock._started_at_ms == t0, "start records started_at_ms")

	var t1 := 1_005_000  # 5 seconds later
	var left := clock.time_left(0, t1)
	_ok(left == START_MS - 5_000, "time_left during running turn: expected %d, got %d" % [START_MS - 5_000, left])

	var t2 := 1_010_000  # stop 10 seconds after start
	clock.stop(t2, 0)
	_ok(clock.running_player == -1, "stop clears running_player")
	var rem := clock.remaining_ms[0]
	_ok(rem == START_MS - 10_000, "remaining after stop: expected %d, got %d" % [START_MS - 10_000, rem])
	_ok(clock.time_left(0, t2 + 1000) == rem, "time_left after stop equals remaining_ms")

	# ---- Lag credit: player 1 starts, stops with lag credit ----
	clock = ChessClock.new()
	clock.start(1, 2_000_000)
	var t3 := 2_003_000  # 3 seconds elapsed
	clock.stop(t3, 500)  # 500ms lag credit
	# spent = 3000 - 500 = 2500, remaining = START_MS - 2500
	_ok(clock.remaining_ms[1] == START_MS - 2_500, "lag credit reduces spend: expected %d, got %d" % [START_MS - 2_500, clock.remaining_ms[1]])

	# ---- Flagging: player 0 with 0 time left ----
	clock = ChessClock.new()
	clock.start(0, 3_000_000)
	var t4 := 3_000_000 + START_MS  # exactly START_MS later -> 0 left
	var flagged := clock.flagged_player(t4)
	_ok(flagged == 0, "flagged_player detects player 0 at exactly 0 ms: got %d" % flagged)
	clock.stop(t4, 0)  # stop player 0 before next test

	# ---- Flagging: player 1 with negative time left (fresh clock) ----
	clock = ChessClock.new()
	clock.start(1, 4_000_000)
	var t5 := 4_000_000 + START_MS + 1  # 1 ms over -> negative
	flagged = clock.flagged_player(t5)
	_ok(flagged == 1, "flagged_player detects player 1 below 0 ms: got %d" % flagged)
	clock.stop(t5, 0)  # stop player 1 before next test

	# ---- Credit never makes a turn negative (fresh clock) ----
	clock = ChessClock.new()
	clock.start(0, 5_000_000)
	# Spend almost all time, then stop with huge lag credit
	var t6 := 5_000_000 + START_MS - 1  # 1 ms left
	clock.stop(t6, 1_000_000)  # lag credit 1 second, more than the 1 ms spent
	# spent = (START_MS - 1) - 1_000_000 = negative -> maxi(spent, 0) = 0
	# remaining should NOT go below 0
	_ok(clock.remaining_ms[0] >= 0, "remaining_ms never negative after huge lag credit: got %d" % clock.remaining_ms[0])
	_ok(clock.remaining_ms[0] == START_MS, "spend clamped to 0 when credit exceeds elapsed: got %d" % clock.remaining_ms[0])

	# ---- time_left for non-running player returns remaining_ms ----
	clock = ChessClock.new()
	clock.start(1, 6_000_000)
	var t7 := 6_001_000
	left = clock.time_left(0, t7)  # player 0 is not running
	_ok(left == clock.remaining_ms[0], "time_left for non-running player returns remaining_ms")

	print("\nCLOCK TESTS %s" % ("PASSED" if not _failed else "FAILED"))
	quit(0 if not _failed else 1)