extends Node2D

#signal hooked(hook_position: Vector2)   ## Emitted when the tip lands on a surface
#signal retracted()                       ## Emitted when fully retracted
#signal pulling_finished()               ## Emitted when player arrives at hook point
 
#@export_group("Speed")
@export var launch_speed: float   = 400.0   ## px/s outward
@export var retract_speed: float  = 300.0   ## px/s inward (idle retract)
@export var pull_speed: float     = 250.0   ## px/s player pulled toward hook
 #
#@export_group("Range")
@export var max_range: float      = 150.0   ## Maximum hookshot reach (px)
@export var arrival_threshold: float = 12.0 ## Distance at which "pull" ends
 #
#@export_group("Chain")
#@export var chain_segment_length: float = 10.0  ## Visual segment spacing
#@export var chain_color: Color = Color(0.85, 0.75, 0.35)   ## Gold-ish
#@export var chain_width: float = 3.0
 #
#@export_group("Layers")
### Physics layers the tip can hook onto (set to your "world" / "hookable" layer)
@export_flags_2d_physics var hookable_layers: int = 3
 
enum State { IDLE, LAUNCHING, HOOKED, RETRACTING, PULLING }
var state: State = State.IDLE
 
@onready var hook: Area2D = $Hook
@onready var chain: Line2D = $Chain
 
var hook_velocity:   Vector2 = Vector2.ZERO
var hook_world_pos:  Vector2 = Vector2.ZERO   ## global position where hook landed
var owner_node:      Node2D  = null            ## the player (set by player script)
 
# ---------------------------------------------------------------------------
# Godot lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_hide_chain()
	_hide_hook()
	# Connect tip collision
	hook.area_entered.connect(_on_hook_area_entered)
	#tip.area_entered.connect(_on_tip_area_entered)
 
 
func _physics_process(delta: float) -> void:
	match state:
		State.LAUNCHING:
			_process_launching(delta)
		State.RETRACTING:
			_process_retracting(delta)
		State.PULLING:
			_process_pulling(delta)
 
	#_update_chain()

func fire(direction: Vector2, player_node: Node2D) -> void:
	if state != State.IDLE:
		return
	owner_node = player_node
	hook.global_position = player_node.global_position
	hook_velocity = direction.normalized() * launch_speed
	_show_hook()
	state = State.LAUNCHING
 
 
## Manually cancel / retract the hookshot (e.g. player pressed action again).
func retract() -> void:
	if state == State.IDLE:
		return
	state = State.RETRACTING
 
 
## Returns true while the hook is doing anything (so player can suppress other actions).
func is_active() -> bool:
	return state != State.IDLE
 
# ---------------------------------------------------------------------------
# State processors
# ---------------------------------------------------------------------------
func _process_launching(delta: float) -> void:
	hook.global_position += hook_velocity * delta
 
	var dist: float = hook.global_position.distance_to(owner_node.global_position)
	if dist >= max_range:
		retract()
 
func _process_retracting(delta: float) -> void:
	var dir: Vector2 = (owner_node.global_position - hook.global_position)
	var dist: float  = dir.length()
 
	if dist <= retract_speed * delta:
		hook.global_position = owner_node.global_position
		_hide_hook()
		state = State.IDLE
		owner_node.state = State.IDLE
		owner_node = null
		#emit_signal("retracted")
	else:
		hook.global_position += dir.normalized() * retract_speed * delta
 
 
func _process_pulling(delta: float) -> void:
	if owner_node == null:
		state = State.IDLE
		return
 
	var dir: Vector2  = hook_world_pos - owner_node.global_position
	var dist: float   = dir.length()
 
	if dist <= arrival_threshold:
		# Player arrived — stop pulling
		_finish_pull()
		return
 
	# Move player toward hook
	var motion: Vector2 = dir.normalized() * pull_speed * delta
 
	# CharacterBody2D path
	if owner_node is CharacterBody2D:
		owner_node.velocity = dir.normalized() * pull_speed
		owner_node.move_and_slide()
	else:
		# Generic Node2D fallback
		owner_node.global_position += motion
 
	# Keep tip pinned to world pos
	hook.global_position = hook_world_pos
 
 
func _finish_pull() -> void:
	if owner_node is CharacterBody2D:
		owner_node.velocity = Vector2.ZERO
		owner_node.state = State.IDLE
	#tip.monitoring = false
	_hide_hook()
	state = State.IDLE
	#emit_signal("pulling_finished")
 
# ---------------------------------------------------------------------------
# Collision handlers
# ---------------------------------------------------------------------------
func _on_hook_area_entered(body: Node2D) -> void:
	if state != State.LAUNCHING:
		return
	# Only hook onto bodies in the correct layers
	print(body)
	print(body.collision_layer)
	if body.collision_layer & hookable_layers == 0:
		return
	print("collided")
	_land_hook()
 
 
func _on_tip_area_entered(area: Area2D) -> void:
	if state != State.LAUNCHING:
		return
	#if area.collision_layer & hookable_layers == 0:
		#return
	_land_hook()
 
 
func _land_hook() -> void:
	hook_world_pos = hook.global_position
	state = State.HOOKED
	#emit_signal("hooked", hook_world_pos)
 
	# Brief pause, then start pulling player
	await get_tree().create_timer(0.08).timeout
	if state == State.HOOKED:   # might have been cancelled during pause
		state = State.PULLING
 
# ---------------------------------------------------------------------------
# Chain visual
# ---------------------------------------------------------------------------
#func _update_chain() -> void:
	#if state == State.IDLE:
		#chain.clear_points()
		#return
 #
	## Draw from player origin (local 0,0) to tip (converted to local space)
	#chain.clear_points()
	#chain.add_point(Vector2.ZERO)
	#var local_tip: Vector2 = to_local(tip.global_position)
	#var dist: float = local_tip.length()
	#var step_count: int = max(1, int(dist / chain_segment_length))
 #
	#for i in range(1, step_count):
		#var t: float = float(i) / float(step_count)
		## Slight sag on the chain when hooked/pulling
		#var sag: float = 0.0
		#if state in [State.HOOKED, State.PULLING]:
			#sag = sin(t * PI) * clamp(dist * 0.04, 0.0, 18.0)
		#chain.add_point(local_tip * t + Vector2(0, sag))
 #
	#chain.add_point(local_tip)
 
# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _show_hook() -> void:
	hook.visible = true 
 
func _hide_hook() -> void:
	hook.visible = false

func _show_chain() -> void:
	chain.visible = true

func _hide_chain() -> void:
	chain.visible = false
	#tip.visible = false
	#chain.clear_points()
