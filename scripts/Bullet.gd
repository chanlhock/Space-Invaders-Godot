# res://scripts/Bullet.gd
extends Area2D

@export var speed = 500.0

func _ready():
	# Connect collision signal
	area_entered.connect(_on_area_entered)

func _process(delta):
	position.y -= speed * delta
	
	# Remove if off-screen
	if position.y < -10:
		queue_free()

func _on_area_entered(area):
	print("🎯 Bullet hit: ", area.name)
	if area.is_in_group("invader"):
		print("✓ Hit an invader!")
		area.take_damage()
		queue_free()
	else:
		print("⚠️ Hit something else: ", area.name)
