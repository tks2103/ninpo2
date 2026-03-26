extends StaticBody2D
 
enum State { IDLE, OPENING, OPEN }
var state: State = State.IDLE

#const vertical_offset: Vector2 = Vector2(10, 100)
 
func _physics_process(delta: float) -> void:
	match state:
		State.OPENING:
			_process_opening(delta)

func open() -> void:
	if state != State.IDLE:
		return
	state = State.OPENING

# ---------------------------------------------------------------------------
# State processors
# ---------------------------------------------------------------------------
func _process_opening(delta: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(
		self,
		"rotation",
		rotation + deg_to_rad(90.0),
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_callback(func() -> void:
		state = State.OPEN
	)
