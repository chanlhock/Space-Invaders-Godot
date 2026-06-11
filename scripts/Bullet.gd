# res://scripts/Bullet.gd
extends Area2D

@export var speed = 500.0

func _process(delta):
	position.y -= speed * delta
	
	# Remove if off-screen
	if position.y < -10:
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("invader"):
		area.take_damage()
		queue_free()
