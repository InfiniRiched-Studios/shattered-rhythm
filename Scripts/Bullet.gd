# Bullet.gd - Create as separate scene (Bullet.tscn) for better performance
extends RigidBody2D

# Movement
var velocity = Vector2(800, 0)
var lifetime = 3.0


export var glow_enabled = true

func _ready():
	# Auto-delete after lifetime
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.connect("timeout", self, "_on_timeout")
	timer.start()
	
	# Connect collision signals
	#connect("area_entered", self, "_on_area_entered")
	# Optional: Add trail effect
	add_trail()

func _process(delta):
	# Move bullet
	position += velocity * delta
	
	# Optional: Fade out near end of lifetime
	if timer_left() < 0.5:
		modulate.a = timer_left() / 0.5

func timer_left():
	for child in get_children():
		if child is Timer:
			return child.time_left
	return 0.0

func _on_area_entered(area):
	# Hit an enemy or target
	if area.is_in_group("enemies") or area.has_method("hit"):
		if area.has_method("hit"):
			area.hit()
		create_hit_effect()
		queue_free()

func _on_body_entered(body):
	# Hit a wall or obstacle
	if body.is_in_group("enemies") or body.has_method("hit"):
		if body.has_method("hit"):
			body.hit()
		create_hit_effect()
		queue_free()

func _on_timeout():
	# Bullet expired
	queue_free()

func create_hit_effect():
	"""Create impact particles"""
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 10
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	particles.spread = 180
	particles.initial_velocity = 150
	#particles.color = bullet_color
	particles.scale_amount = 3.0
	get_tree().root.add_child(particles)
	
	# Clean up particles after they finish
	var timer = Timer.new()
	particles.add_child(timer)
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.connect("timeout", particles, "queue_free")
	timer.start()

func add_trail():
	"""Add trail effect behind bullet"""
	if glow_enabled:
		var trail = CPUParticles2D.new()
		trail.emitting = true
		trail.amount = 8
		trail.lifetime = 0.2
		trail.local_coords = false
		trail.direction = Vector2(-1, 0)
		trail.spread = 5
		trail.initial_velocity = 50
		#trail.color = bullet_color
		trail.scale_amount = 2.0
		add_child(trail)

# === BULLET.TSCN STRUCTURE ===
# Create this scene for better reusability:
#
# Area2D (Bullet)
# ├─ CollisionShape2D (RectangleShape2D, 10x3)
# ├─ Visual (ColorRect or Polygon2D)
# │  └─ Glow (Light2D or duplicate ColorRect with Add blend)
# └─ Trail (CPUParticles2D)
#
# Attach this script to the Area2D root
