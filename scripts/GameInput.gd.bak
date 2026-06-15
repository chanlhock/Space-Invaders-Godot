# res://scripts/GameInput.gd
extends Node

var joystick_x = 0.0
var joystick_y = 0.0
var button_pressed = false
var connected = false

# UDP Listener for Pico W Data (Port 9000)
var udp := UDPServer.new()

func _ready():
	udp.listen(9000)
	print("Listening for Pico W data on port 9000...")

func _process(_delta):
	if udp.is_connection_available():
		var peer = udp.take_connection()
		var packet = peer.get_packet()
		var data_string = packet.get_string_from_utf8()
		
		# Expected format: "X:123,Y:456,BTN:1"
		parse_pico_data(data_string)
		peer.close()

func parse_pico_data(data: String):
	var parts = data.split(",")
	for part in parts:
		if part.begins_with("X:"):
			joystick_x = float(part.substr(2)) / 65535.0 # Normalize 0-1
		elif part.begins_with("Y:"):
			joystick_y = float(part.substr(2)) / 65535.0
		elif part.begins_with("BTN:"):
			button_pressed = int(part.substr(4)) == 1
	
	connected = true
