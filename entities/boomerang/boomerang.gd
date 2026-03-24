extends CharacterBody2D

# ── State Machine ──────────────────────────────────────────────────────────────
enum State { IDLE, THROWN, RETURNING }
var state: State = State.IDLE

# ── Tuning ─────────────────────────────────────────────────────────────────────
const MAX_DISTANCE    := 220.0   # How far it flies before auto-returning
const FLY_SPEED       := 380.0   # Outward speed (pixels/sec)
const RETURN_SPEED    := 320.0   # Return speed – accelerates toward player
const RETURN_ACCEL    := 600.0   # Return acceleration (pixels/sec²)
const SPIN_SPEED      := 9.0     # Rotation speed (radians/sec)
const WOBBLE_AMP      := 28.0    # Side-to-side wobble amplitude
const WOBBLE_FREQ     := 3.8     # Wobble frequency

# ── Runtime state ──────────────────────────────────────────────────────────────
var throw_origin:    Vector2 = Vector2.ZERO
var throw_direction: Vector2 = Vector2.RIGHT
var travel_distance: float   = 0.0
var return_velocity: Vector2 = Vector2.ZERO
var wobble_time:     float   = 0.0

# ── Visuals ────────────────────────────────────────────────────────────────────
var trail_points: Array[Vector2] = []
const TRAIL_LENGTH := 12

# ── Player reference ───────────────────────────────────────────────────────────
@onready var player: CharacterBody2D = get_parent().get_node("Player")

# ── Trail rendering ────────────────────────────────────────────────────────────
var trail_line: Line2D

func _ready() -> void:
	visible = false

	# Create a Line2D for the motion trail
	trail_line = Line2D.new()
	trail_line.width = 4.0
	trail_line.default_color = Color(1.0, 0.85, 0.2, 0.6)
	trail_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail_line.end_cap_mode   = Line2D.LINE_CAP_ROUND
	get_parent().add_child(trail_line)
	trail_line.z_index = -1


# ── Public API ─────────────────────────────────────────────────────────────────

func throw(origin: Vector2, direction: Vector2) -> void:
	throw_origin    = origin
	throw_direction = direction.normalized()
	travel_distance = 0.0
	wobble_time     = 0.0
	return_velocity = Vector2.ZERO
	trail_points.clear()

	global_position = origin
	visible         = true
	state           = State.THROWN

func recall() -> void:
	if state == State.THROWN:
		state = State.RETURNING
		# Give the return an initial nudge toward the player
		return_velocity = (player.global_position - global_position).normalized() * (FLY_SPEED * 0.5)


# ── Processing ─────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	match state:
		State.THROWN:
			_process_thrown(delta)
		State.RETURNING:
			_process_returning(delta)
		State.IDLE:
			_update_trail()

	# Spin regardless of state while visible
	if visible:
		rotation += SPIN_SPEED * delta
		_update_trail()


func _process_thrown(delta: float) -> void:
	wobble_time += delta

	# Primary forward movement
	var forward := throw_direction * FLY_SPEED * delta

	# Perpendicular wobble (like a Zelda boomerang arcing side to side)
	var perp    := Vector2(-throw_direction.y, throw_direction.x)
	var wobble  := perp * sin(wobble_time * WOBBLE_FREQ) * WOBBLE_AMP * delta

	global_position += forward + wobble
	travel_distance += FLY_SPEED * delta

	# Auto-return once max distance is reached
	if travel_distance >= MAX_DISTANCE:
		state = State.RETURNING
		return_velocity = (player.global_position - global_position).normalized() * FLY_SPEED * 0.4


func _process_returning(delta: float) -> void:
	var to_player := player.global_position - global_position
	var dist      := to_player.length()

	# Accelerate toward the player
	return_velocity = return_velocity.move_toward(
		to_player.normalized() * (RETURN_SPEED + RETURN_ACCEL * delta),
		RETURN_ACCEL * delta
	)

	global_position += return_velocity * delta

	# Caught by the player
	if dist < 20.0:
		_catch()


func _catch() -> void:
	visible = false
	state   = State.IDLE
	trail_points.clear()
	trail_line.clear_points()

	# Small screen-shake / feedback could go here
	#_flash_player()
#
#
#func _flash_player() -> void:
	#var tween := create_tween()
	#var sprite_node: Polygon2D = player.get_node("Sprite")
	#tween.tween_property(sprite_node, "color", Color.WHITE, 0.06)
	#tween.tween_property(sprite_node, "color", Color(0.2, 0.6, 1.0, 1), 0.12)


# ── Trail ──────────────────────────────────────────────────────────────────────

func _update_trail() -> void:
	if not visible:
		trail_line.clear_points()
		return

	trail_points.append(global_position)
	if trail_points.size() > TRAIL_LENGTH:
		trail_points.pop_front()

	trail_line.clear_points()
	for i in trail_points.size():
		trail_line.add_point(trail_points[i])
		# Fade alpha along trail
		var alpha := float(i) / float(trail_points.size())
		#trail_line.set_point_color(i, Color(1.0, 0.85, 0.2, alpha * 0.7))
