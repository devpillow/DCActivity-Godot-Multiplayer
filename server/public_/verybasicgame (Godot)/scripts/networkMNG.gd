extends Node

const CLIENTID:String = "yourClientIdHere"
const SOCKET_URL:String = "wss://"+CLIENTID+".discordsays.com/.proxy/api"

var socket = WebSocketPeer.new()
var my_id = ""
var username = ""
var avatar_url = ""

var known_users = {} # รายชื่อคนที่เคยเจอแล้ว
var time_counter = 0.0

var mainWorld:MainWorld

func _ready():
	print("🚀 Game Version: 1.0.5.7")
	print("--- เริ่มทำงาน ID ของฉันคือ: ", my_id, " ---")
	socket.connect_to_url(SOCKET_URL)
	print("⏳ กำลังรอ Discord...")
	
	DiscordManager.discord_connected.connect(_on_discord_ready)
	DiscordManager.discord_error.connect(_on_discord_fail)

func _on_discord_ready():
	print(" Discord Ready !")
	
	while my_id == "" or username=="" :
		await Global.wait(0.64) #untill my_id is set
		print("[i] Godot Trying to get discordID")
	await Global.wait(0.01)
	mainWorld= get_tree().get_first_node_in_group("MainWorld")
	
	await Global.wait(0.01)
	var spawnPos:Vector2 = Vector2(randf()*80,randf()*80)
	mainWorld.spawnPlayer(str(my_id),username,spawnPos)
	Global.players.get(my_id).set_pfp_by_url(avatar_url)
	NetworkMng._broadcast_playerSpawned(spawnPos) #บอกคนอื่นว่า ตัวเอง spawn แล้ว เพื่อให้คนอื่น spawn ตัวเราขึ้นมา

func _on_discord_fail(error):
	print("Error occurred: ", error)
	# แสดงหน้าจอ Error ให้ผู้เล่นเห็น
	mainWorld= get_tree().get_first_node_in_group("MainWorld")
	mainWorld.Ui.ErrorDisplayer.show()


var dcTime = 6
func _process(delta):
	socket.poll() # สั่งให้ WebSocket ทำงาน
	
	var state = socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		# 1. อ่านข้อมูลที่ส่งเข้ามา
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet().get_string_from_utf8()
			var data = JSON.parse_string(packet)
			
			if data:
				_handle_message(data)
		
		# 2. ตะโกนบอกคนอื่นทุกๆ 2 วินาที ว่า "ฉันอยู่นี่"
		time_counter += delta
		if time_counter >= 2.0:
			_broadcast_playerCheck()
			time_counter = 0.0
		
		if time_counter == 0 :
			for _user in known_users.keys():
				if known_users[_user] > 0 :
					known_users[_user] -= 2
					print("[i] checking the user " + _user + " if disconected or not.")
					if known_users[_user] <dcTime -3 : 
						Global.players[_user].modulate = Color(0.6, 0.6, 0.6, 0.8)
						print("[i] the user " + _user + " is disconected.")
					else : Global.players[_user].modulate = Color(1, 1, 1, 1)
				else : # remove the player if _broadcast_playerCheck for 10 sec
					Global.players[_user].queue_free()
					Global.players.erase(_user)
					known_users.erase(_user)
					print("[i] " +_user+" left the game")

		
		
	elif state == WebSocketPeer.STATE_CLOSED:
		print("Server ตัดการเชื่อมต่อ")

# ฟังก์ชันจัดการข้อความที่ได้รับ
func _handle_message(data):
	var _dataType = data.get("type")
	print("[i] ได้รับสัญญาณ Type : ",_dataType)
	match _dataType :
		"playerCheck" :
			print("[i] ได้รับสัญญาณ playerCheck")
			var _data = data.get("data1")
			# ถ้าเป็นข้อความจากตัวเอง ให้ข้ามไป
			if _data == my_id:
				return
		
			# เช็คว่าคนนี้เป็นคนหน้าใหม่หรือไม่?
			if not known_users.has(_data):
				print("[i] กำลังโหลดคนใหม่เข้ามาในห้อง! ID: ", _data)
			if known_users.has(_data):
				known_users[_data] = 10

			else: pass
			
		"syncNeeded": # ถ้า Id ยังไม่ถูกเพิ่มใน known_users ให้เพิ่มใน known_users และ spawn
			print("[i] ได้รับสัญญาณ syncNeeded")
			var _id = data.get("data2")
			
			if not known_users.has(_id):
				print("[i] โหลดคนใหม่เข้ามาในห้อง! ID: ", _id , " (จากสัญญาณ syncNeeded)")
				known_users[_id] = dcTime
				
				var _data1 = data.get("data1")
				var _pos = Vector2(_data1["x"],_data1["y"])
				
				var _username = data.get("data3")
				var _avatar_url = data.get("data4")
				
				mainWorld.spawnPlayer(str(_id),_username,_pos)
				Global.players.get(str(_id)).set_pfp_by_url(_avatar_url)

				
		"playerSpawned" :
			print("[i] ได้รับสัญญาณ playerSpawned")
			var _data1 = data.get("data1")
			var _pos = Vector2(_data1["x"],_data1["y"])
			#var _data2 = data.get("data2")
			var _id = data.get("data2")
			var _username = data.get("data3")
			var _avatar_url = data.get("data4")
			
			#`https://cdn.discordapp.com/avatars/${userData.id}/${userData.avatar}.png`;
			mainWorld.spawnPlayer(str(_id),_username,_pos)
			Global.players.get(str(_id)).set_pfp_by_url(_avatar_url)
			
			_broadcast_syncNeeded(Global.players[str(my_id)].position) #มีคนใหม่เข้ามา(สร้างตัวเอง) ต้องส่งข้อมูลตัวเองให้ (id , name กับ pos)
			
		"playerMoving" :
			print("[i] ได้รับสัญญาณ playerMoving")
			var _data1 = data.get("data1")
			var _pos = Vector2(_data1["x"],_data1["y"])
			var _id = data.get("data2")
			if Global.getOnlinePlayer() > 1 :
				Global.players[str(_id)]._on_network_position_received(_pos)

		"playerSpeak" :
			var _id = data.get("data1")
			var _isVoicing = data.get("data2")
			print("[i] ได้รับสัญญาณจาก"+_id+" VOICE_STATE : " + str(_isVoicing))
			Global.players.get(str(_id)).setVoicing(_isVoicing)

			


# ฟังก์ชันส่งข้อมูลออกไ ใช้เช็คผู้เล่น
func _broadcast_playerCheck():
	print("[i] มีการ _broadcast_playerCheck")
	var packet = {
		"type" : "playerCheck",
		"data1": my_id,
	}
	socket.put_packet(JSON.stringify(packet).to_utf8_buffer())

func _broadcast_playerSpawned(pos_:Vector2i):
	print("[i] มีการ _broadcast_playerSpawned")
	var packet = {
		"type" : "playerSpawned",
		"data1": {"x" : pos_.x ,  "y" : pos_.y},
		"data2": my_id,
		"data3": username,
		"data4": avatar_url,
	}
	socket.put_packet(JSON.stringify(packet).to_utf8_buffer())

func _broadcast_playerMoving(pos_:Vector2i):
	print("[i] มีการ _broadcast_playerMoving")
	var packet = {
		"type" : "playerMoving",
		"data1": {"x" : pos_.x ,  "y" : pos_.y},
		"data2": my_id,
	}
	socket.put_packet(JSON.stringify(packet).to_utf8_buffer())

func _broadcast_syncNeeded(pos_): #id , name กับ pos)
	print("[i] มีการ _broadcast_syncNeeded")
	var packet = {
		"type" : "syncNeeded",
		"data1": {"x" : pos_.x ,  "y" : pos_.y},
		"data2": my_id,
		"data3": username,
		"data4": avatar_url,
	}
	socket.put_packet(JSON.stringify(packet).to_utf8_buffer())

func _broadcast_playerSpeak(is_speak:bool):
	print("[i] มีการ _broadcast_playerSpeak")
	var packet = {
		"type" : "playerSpeak",
		"data1": my_id,
		"data2": is_speak,

	}
	socket.put_packet(JSON.stringify(packet).to_utf8_buffer())
