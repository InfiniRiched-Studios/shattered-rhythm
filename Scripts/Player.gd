extends KinematicBody2D

# Cannon references
onready var cannon_upper = $CannonUpper
onready var cannon_center = $CannonCenter
onready var cannon_lower = $CannonLower

# Body parts
onready var body = $Body
onready var core_glow = $Body/CoreGlow

# Floating animation
var float_offset = 0.0
var float_speed = 1.5
var float_amplitude = 8.0

func _ready():
	start_core_pulse()

func _process(delta):
	# Idle floating animation
	float_offset += delta * float_speed
	position.y += sin(float_offset) * float_amplitude * delta

func start_core_pulse():
	# Pulse the glowing core
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(core_glow, "scale", 
		Vector2(1.0, 1.0), Vector2(1.2, 1.2), 
		0.8, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.interpolate_property(core_glow, "scale", 
		Vector2(1.2, 1.2), Vector2(1.0, 1.0), 
		0.8, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.8)
	tween.set_repeat(true)
	tween.start()

func shoot_lane(lane_index: int):
	"""Trigger shoot animation for specific lane (0=upper, 1=center, 2=lower)"""
	match lane_index:
		0:
			if cannon_upper.has_method("shoot"):
				cannon_upper.shoot()
		1:
			if cannon_center.has_method("shoot"):
				cannon_center.shoot()
		2:
			if cannon_lower.has_method("shoot"):
				cannon_lower.shoot()

func shoot_multiple(lane_indices: Array):
	"""Shoot from multiple lanes simultaneously"""
	for idx in lane_indices:
		shoot_lane(idx)
	
	# Extra visual feedback for multi-shot
	if lane_indices.size() >= 3:
		flash_body()

func flash_body():
	"""Flash the body when shooting all lanes"""
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(body, "modulate", 
		Color(1.5, 1.5, 2.0), Color.white, 
		0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	tween.queue_free()

func take_damage():
	"""Visual feedback when taking damage (if implementing health system)"""
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(body, "modulate", 
		Color.red, Color.white, 
		0.15, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	tween.queue_free()

func on_beat():
	"""Called by conductor on each beat for visual sync"""
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(core_glow, "modulate:a", 
		1.0, 0.6, 
		0.1, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	tween.queue_free()


func _physics_process(_delta):
	# Getting the input from the player
	if Input.is_action_just_pressed("UPLANE_SHOOT"):
		$CannonUpper.shoot()
	if Input.is_action_just_pressed("LOWERLANE_SHOOT"):
		$CannonLower.shoot()
