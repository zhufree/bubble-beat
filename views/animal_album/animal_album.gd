extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	if Input.is_action_just_pressed("left"):
		$CarouselContainer._left()
	if Input.is_action_just_pressed("right"):
		$CarouselContainer._right()
	if Input.is_action_just_pressed("E"):
		$ColorRect.visible = true
		$ColorRect/Timer.start()


func _on_timer_timeout() -> void:
	$ColorRect.visible = false
