extends RigidBody2D

enum State {
	IDLE,
	FALLING,
	ROLLING,
	CRASHED
}

const height: int = -90
const initial_speed: int = 2
const acceleration: int = 1.6
const max_speed: int = 5

var speed: float = initial_speed
var state: State = State.IDLE
var root_position: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	root_position = self.global_position
	self.collision_layer = 0
	self.collision_mask = 0
	self.body_entered.connect(_on_body_entered)
	reset()

func _physics_process(delta: float) -> void:
	if state == State.FALLING:
		self.global_position.y += speed
		speed += acceleration
		if self.global_position.y >= root_position.y:
			roll()
	elif state == State.ROLLING:
		speed += min(acceleration + speed, max_speed)
		self.linear_velocity.y = speed


func fall() -> void:
	state = State.FALLING
	self.visible = true

func roll() -> void:
	state = State.ROLLING
	self.collision_mask = 1
	self.collision_layer = 1

func reset() -> void:
	self.visible = false
	animated_sprite.play("idle")
	self.global_position = root_position
	self.global_position.y += height
	speed = initial_speed
	state = State.IDLE
	await get_tree().create_timer(2.0).timeout
	fall()

func _on_body_entered(body: Node2D) -> void:
	print("collided")
	self.collision_layer = 0
	self.collision_mask = 0
	self.linear_velocity = Vector2.ZERO
	state = State.CRASHED
	await get_tree().create_timer(5.0).timeout
	reset()
