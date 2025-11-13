# Cannon.gd - Attach to CannonUpper, CannonCenter, CannonLower nodes
extends Node2D

# References
onready var barrel = $CannonBarrel
onready var muzzle_flash = $MuzzleFlash
onready var shoot_ray = $ShootRay
onready var particles = $Particles

# Bullet settings
export var bullet_speed = 800.0
export var bullet_color = Color(0, 1, 1)  # Cyan
export var bullet_size = Vector2(20, 6)

var original_barrel_pos = Vector2.ZERO

# Bullet scene (preload if you have a separate scene)
var Bullet = preload("res://objects/Bullet.tscn")

func _ready():
	muzzle_flash.visible = false
	original_barrel_pos = barrel.position

func shoot():
	"""Trigger shooting animation and spawn bullet"""
	# Spawn bullet
	spawn_bullet()
	
	# Muzzle flash
	show_muzzle_flash()
	
	# Barrel recoil
	barrel_recoil()
	
	# Particle burst
	if particles:
		particles.emitting = true
		particles.restart()
	
	# Ray flash
	if shoot_ray:
		flash_ray()

func spawn_bullet():
	"""Create and launch a bullet"""
	var bullet
	
	# Use custom bullet scene if it exists, otherwise create simple bullet
	if Bullet:
		bullet = Bullet.instance()
	else:
		bullet = create_simple_bullet()
	
	# Position bullet at muzzle
	bullet.global_position = muzzle_flash.global_position
	
	# Set velocity (shooting right)
	bullet.velocity = Vector2(bullet_speed, 0)
	
	# Add to scene tree (add to root or specific bullets container)
	get_tree().root.add_child(bullet)

func create_simple_bullet():
	"""Create a simple bullet using Area2D and visual"""
	var bullet = Area2D.new()
	bullet.name = "Bullet"
	
	# Visual representation
	var visual = ColorRect.new()
	visual.rect_size = bullet_size
	visual.rect_position = -bullet_size / 2  # Center it
	visual.color = bullet_color
	bullet.add_child(visual)
	
	# Collision shape
	var shape = RectangleShape2D.new()
	shape.extents = bullet_size / 2
	var collision = CollisionShape2D.new()
	collision.shape = shape
	bullet.add_child(collision)
	
	# Add script for movement
	
	return bullet

func show_muzzle_flash():
	"""Show and fade out muzzle flash"""
	muzzle_flash.visible = true
	muzzle_flash.modulate.a = 1.0
	
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(muzzle_flash, "modulate:a", 
		1.0, 0.0, 
		0.15, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	muzzle_flash.visible = false
	muzzle_flash.modulate.a = 1.0
	tween.queue_free()

func barrel_recoil():
	"""Animate barrel recoil effect"""
	var recoil_pos = original_barrel_pos + Vector2(-15, 0)
	
	var tween = Tween.new()
	add_child(tween)
	
	# Recoil back
	#tween.interpolate_property(barrel, "position", 
		#original_barrel_pos, recoil_pos, 
		#0.05, Tween.TRANS_BACK, Tween.EASE_OUT)
	
	# Return to original position
	tween.interpolate_property(barrel, "position", 
		recoil_pos, original_barrel_pos, 
		0.1, Tween.TRANS_ELASTIC, Tween.EASE_OUT, 0.05)
	
	tween.start()
	yield(tween, "tween_completed")
	tween.queue_free()

func flash_ray():
	"""Flash the raycast for visual effect"""
	if not shoot_ray.visible:
		shoot_ray.visible = true
	
	shoot_ray.modulate = Color(0, 1, 1, 1)  # Bright cyan
	
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(shoot_ray, "modulate:a", 
		1.0, 0.0, 
		0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	tween.queue_free()
