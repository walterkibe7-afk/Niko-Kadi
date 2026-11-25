
class_name ChessClock
extends RefCounted

const START_MS := 600_000

var remaining_ms: Array[int] = [START_MS, START_MS]
var running_player := -1
var _started_at_ms := 0
var _paused := false


func start(player: int, now_ms: int) -> void:
	assert(running_player == -1, "clock is already running")
	assert(player == 0 or player == 1, "bad player index")

	running_player = player
	_started_at_ms = now_ms
	_paused = false


# lag_credit_ms is the measured RTT of the player who just moved.
func stop(now_ms: int, lag_credit_ms: int) -> void:
	assert(running_player != -1, "clock is not running")
	assert(lag_credit_ms >= 0, "negative lag credit")

	if not _paused:
		var spent := now_ms - _started_at_ms - lag_credit_ms
		remaining_ms[running_player] -= maxi(spent, 0)

	running_player = -1
	_paused = false


func time_left(player: int, now_ms: int) -> int:
	if player == running_player and not _paused:
		return remaining_ms[player] - (now_ms - _started_at_ms)

	return remaining_ms[player]


func flagged_player(now_ms: int) -> int:
	for p in 2:
		if time_left(p, now_ms) <= 0:
			return p

	return -1


func pause(now_ms: int) -> void:
	if running_player == -1 or _paused:
		return

	remaining_ms[running_player] -= maxi(now_ms - _started_at_ms, 0)
	_paused = true


func resume(now_ms: int) -> void:
	if running_player == -1 or not _paused:
		return

	_started_at_ms = now_ms
	_paused = false
