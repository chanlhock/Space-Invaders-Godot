  # res://scripts/Bullet.gd
extends Area2D

@export var speed = 500.0

func _ready():
	# Connect the collision signal
	area_entered.connect(_on_area_entered)
	print("🔫 Bullet spawned at position: ", position)

func _process(delta):
	position.y -= speed * delta
	
	# Remove if off-screen
	if position.y < -10:
		queue_free()

func _on_area_entered(area):
	print("🎯 Bullet hit: ", area.name)
	if area.is_in_group("invader"):
		print("✓ Hit an invader!")
		# Play explosion sound
		var main = get_node_or_null("/root/Main")
		if main and main.has_node("AudioPlayers/ExplosionPlayer"):
			main.get_node("AudioPlayers/ExplosionPlayer").play()
			print("🔊 Playing explosion sound")
		area.take_damage()
		queue_free()
	else:
		print("⚠️ Hit something else: ", area.name)
