# res://scripts/Bullet.gd
extends Area2D

@export var speed = 500.0

func _process(delta):
	position.y -= speed * delta
	
	# Remove if off-screen
	if position.y < -10:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("invader"):
		body.take_damage()
		queue_free()
