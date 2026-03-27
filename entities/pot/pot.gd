extends RigidBody2D
 
enum State { IDLE, LIFTED, THROWN, BROKEN }
var state: State = State.IDLE

const vertical_offset: Vector2 = Vector2(0, -32)
const launch_speed: int = 200
const max_range: int = 100

var thrown_location: Vector2 = Vector2.ZERO
var owner_node:      Node2D  = null            ## the player (set by player script)
 
func _physics_process(delta: float) -> void:
	match state:
		State.LIFTED:
			_process_lifted(delta)
		State.THROWN:
			_process_thrown(delta)

func lift(direction: Vector2, player_node: Node2D) -> void:
	if state != State.IDLE:
		return
	state = State.LIFTED
	owner_node = player_node
	global_transform.origin = owner_node.global_position + vertical_offset

func throw(direction: Vector2) -> void:
	if state != State.LIFTED:
		return
	state = State.THROWN
	thrown_location = owner_node.global_position + vertical_offset
	linear_velocity = direction.normalized() * launch_speed
	if direction.y == 0:
		linear_velocity.y += 40

# ---------------------------------------------------------------------------
# State processors
# ---------------------------------------------------------------------------
func _process_lifted(delta: float) -> void:
	global_transform.origin = owner_node.global_position + vertical_offset
 
func _process_thrown(delta: float) -> void:
	if global_position.distance_to(thrown_location) >= max_range:
		queue_free()
		linear_velocity = Vector2.ZERO
		state = State.BROKEN
