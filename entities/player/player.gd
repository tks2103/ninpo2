extends CharacterBody2D

enum State {
	IDLE,
	WALK
}

@export_category("Stats")
@export var speed: int = 500

var state: State = State.IDLE
var move_direction: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = \
	$AnimationTree["parameters/playback"]

func _physics_process(delta: float) -> void:
	move()

func log_location() -> void:
	print(int(position.x / 16), " ", int(position.y / 16))

func move() -> void:
	move_direction.x = 	int(Input.is_action_pressed("right")) - \
						int(Input.is_action_pressed("left"))
	move_direction.y = 	int(Input.is_action_pressed("down")) - \
						int(Input.is_action_pressed("up"))
	var motion: Vector2 = move_direction.normalized() * speed
	set_velocity(motion)
	move_and_slide()
	
	if motion != Vector2.ZERO and state == State.IDLE:
		state = State.WALK
		update_animation()
	elif motion == Vector2.ZERO and state == State.WALK:
		state = State.IDLE
		update_animation()
	
	if state == State.WALK:
		log_location()


func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.WALK:
			animation_playback.travel("walk")
