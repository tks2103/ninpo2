extends CharacterBody2D

enum State {
	IDLE,
	HOOKSHOTTING,
	WALK
}

enum ActiveItem { HOOKSHOT, BOOMERANG }
var active_item: ActiveItem = ActiveItem.BOOMERANG

@export_category("Stats")
@export var speed: int = 500

var state: State = State.IDLE
var move_direction: Vector2 = Vector2.ZERO

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = \
	$AnimationTree["parameters/playback"]

const BoomerangScene: PackedScene = preload("res://entities/boomerang/boomerang.tscn")
const HookshotScene: PackedScene = preload("res://entities/hookshot/hookshot.tscn")

var hookshot: CharacterBody2D = null

func _physics_process(delta: float) -> void:
	input()
	move()
	act()

func log_location() -> void:
	print(int(position.x / 16), " ", int(position.y / 16))

func input() -> void:
	if Input.is_action_just_released("swap"):
		active_item = (active_item + 1) % ActiveItem.size()

func move() -> void:
	if state == State.HOOKSHOTTING:
		return
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
		#log_location()
		pass

func act() -> void:
	if state == State.HOOKSHOTTING:
		return
	if Input.is_action_just_pressed("action"):
		match active_item:
			ActiveItem.HOOKSHOT:
				print("launch hookshot")
				if not hookshot:
					hookshot = HookshotScene.instantiate()
					get_parent().add_child(hookshot)
				hookshot.fire(Vector2(1, 0), self)
				state = State.HOOKSHOTTING
			ActiveItem.BOOMERANG:
				print("throw boomerang")
				var boomerang: CharacterBody2D = BoomerangScene.instantiate()
				get_parent().add_child(boomerang)
				boomerang.global_position = global_position
				boomerang.throw(global_position, Vector2(1, 0))


func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.WALK:
			animation_playback.travel("walk")
