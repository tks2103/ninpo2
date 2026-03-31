extends Area2D

enum State {
	IDLE,
	FALLING,
	CRUMBLING
}

const height: int = -90
const initial_speed: int = 2
const acceleration: int = 1.6

var speed: float = initial_speed
var state: State = State.IDLE
var root_position: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	root_position = self.global_position
	reset()

func _physics_process(delta: float) -> void:
	if state == State.FALLING:
		self.global_position.y += speed
		speed += acceleration
		if self.global_position.y >= root_position.y:
			crumble()

func fall() -> void:
	state = State.FALLING
	self.visible = true
	
func crumble() -> void:
	state = State.CRUMBLING
	animated_sprite.play("Crumble")
	await get_tree().create_timer(0.3).timeout
	reset()

func reset() -> void:
	self.visible = false
	animated_sprite.play("Idle")
	self.global_position.y += height
	speed = initial_speed
	await get_tree().create_timer(2.0).timeout
	state = State.IDLE
	fall()
