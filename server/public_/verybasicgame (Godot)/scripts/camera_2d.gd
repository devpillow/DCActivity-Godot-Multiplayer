extends Camera2D

var zp = 6
func _input(event):
	if Input.is_action_just_pressed("zoom_in"):
		self.zoom *= zp*pow(10,-1)
		
	if Input.is_action_just_pressed("zoom_out"):
		self.zoom *= 10*pow(zp,-1)
