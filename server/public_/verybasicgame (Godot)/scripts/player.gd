extends CharacterBody2D
class_name Player
@export var max_speed = 850
@export var accel = 8600
@export var fliction = 8300

var input:Vector2

var player_id:String
var player_name:String

@onready var nicknameLbl = $Label
@onready var camera = $Camera2D

var debug:bool = false

func _ready() -> void:
	await Global.wait(0.01)
	if NetworkMng.my_id == player_id : 
		camera.enabled = true
		
	else : camera.enabled = false
	
func get_input():
	
	if NetworkMng.my_id != player_id and !debug: return Vector2.ZERO
	
	input.x = int(Input.is_action_pressed('move_right')) - int(Input.is_action_pressed('move_left'))
	input.y = int(Input.is_action_pressed('move_down')) - int(Input.is_action_pressed('move_up'))
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) : input = get_local_mouse_position()
	return input.normalized()
	
var broadcastCooldown:float = 0.1
var broadcastCdLeft:float =0.2
	
func player_movement(delta):
	input = get_input()
	if input == Vector2.ZERO:
		#print('not moving')
		if velocity.length() > fliction*delta :
			#print(fliction*delta)
			velocity -= velocity.normalized()* (fliction*delta)
		else : velocity = Vector2.ZERO
		#print(velocity.length())
	else : 
		velocity += input*accel*delta 
		velocity = velocity.limit_length(max_speed)

	if broadcastCdLeft >0 : 
		broadcastCdLeft = broadcastCdLeft - delta
		if broadcastCdLeft < 0 : broadcastCdLeft =0
		
	elif velocity.length_squared() > 1 and broadcastCdLeft <= 0:
		broadcastCdLeft = broadcastCooldown
		NetworkMng._broadcast_playerMoving(position)
	


func _physics_process(delta):
	player_movement(delta)
	move_and_slide()
	play_anim()



func set_nickname(_nickname :String) :
	if _nickname != "" :
		player_name = _nickname
		nicknameLbl.text = _nickname
	else :
		player_name = "player" + str(player_id)
		nicknameLbl.text = "player" + str(player_id)
		
func set_pfp_by_url(avatar_url:String):
# 2. โหลดรูปโปรไฟล์
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_avatar_loaded)
		
		# ยิงคำขอโหลดรูป
	http_request.request(avatar_url)

func _on_avatar_loaded(result, response_code, headers, body):
	if response_code == 200:
		var image = Image.new()
		
		var error = image.load_png_from_buffer(body) # ปกติ Discord ส่งมาเป็น PNG หรือ WebP
		image.resize(20, 20, Image.INTERPOLATE_BILINEAR)
		if error == OK:
			var texture = ImageTexture.create_from_image(image)
			$Pfp.texture = texture # เย้! รูปขึ้นแล้ว
			# สั่งให้มันขยาย/หดตามขนาดที่เรากำหนด
			$Pfp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			$Pfp.custom_minimum_size = Vector2(20, 20)
			$Pfp.size = Vector2(20, 20) # บางทีต้องกำหนดอันนี้ด้วยถ้าไม่ได้อยู่ใน Container


#func _on_network_position_received(new_pos: Vector2):
#
	#position = new_pos
var move_tween: Tween

func _on_network_position_received(new_pos: Vector2):
	# ถ้ามี Tween เก่าที่ยังทำงานอยู่ให้ Kill ทิ้งก่อน เพื่อไม่ให้มันขัดกัน
	if move_tween:
		move_tween.kill()
	
	move_tween = create_tween()
	move_tween.tween_property(self, "global_position", new_pos, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


var lFramePos:Vector2 = Vector2.ZERO
var facing_dir: String = "s" # เก็บทิศทางล่าสุด (ตั้งค่าเริ่มต้นเป็น "s" หรือหันหน้าลง)
@export var animSprite:AnimatedSprite2D
@export var animSpriteback:AnimatedSprite2D
func play_anim() -> void:
	var cFramePos: Vector2 = self.global_position

	# กำหนดค่าเริ่มต้นในเฟรมแรกเพื่อไม่ให้คำนวณผิดพลาด
	if lFramePos == Vector2.ZERO: 
		lFramePos = self.global_position
	
# หาระยะการกระจัด
	var movement: Vector2 = cFramePos - lFramePos
	
# ถ้ามีการเคลื่อนที่ (ใช้ != Vector2.ZERO เพื่อเช็คว่าขยับจริงไหม)
	if movement != Vector2.ZERO:
# เช็คว่าขยับในแกน X หรือ Y มากกว่ากัน เพื่อหาทิศทางหลัก
		if abs(movement.x) > abs(movement.y):
			if movement.x > 0:
				facing_dir = "d" # ขวา
			else:
				facing_dir = "a" # ซ้าย
		else:
			if movement.y > 0:
				facing_dir = "s" # ลง
			else:
				facing_dir = "w" # ขึ้น
# เล่นแอนิเมชันเดิน พร้อมบวก string ทิศทางเข้าไป
		animSprite.play("walk(" + facing_dir + ")")
	else:
		# ถ้าไม่มีการเคลื่อนที่ ให้เล่น idle ตามทิศทางล่าสุดที่หันหน้าอยู่
		animSprite.play("idle(" + facing_dir + ")")
	
	# อัปเดตตำแหน่งเฟรมปัจจุบันไปเก็บไว้ใช้เทียบในเฟรมถัดไป
	lFramePos = cFramePos
	
	animSpriteback.play(animSprite.animation)

func setVoicing(_voice:bool = false):
	if _voice : animSpriteback.show()
	else : animSpriteback.hide()
