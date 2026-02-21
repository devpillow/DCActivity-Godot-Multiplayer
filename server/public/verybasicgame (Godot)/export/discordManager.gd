extends Node #DiscordMNG ~= DiscordBridge

# Signal เพื่อบอกส่วนอื่นของเกมว่า Discord พร้อมแล้ว
signal discord_connected(user_code)
signal discord_error(message)

var _js_callback_ref = null # เก็บ reference กัน Garbage Collector ลบ

func _ready():
	if OS.has_feature("web"):
		_setup_discord_bridge()
	else:
		print("ไม่ได้รันบน Web, ข้ามการเชื่อมต่อ Discord")

func _setup_discord_bridge():
	# 1. สร้าง Callback Function ที่ JavaScript จะเรียกกลับมาหาเรา
	var js_callback = JavaScriptBridge.create_callback(_on_js_message)
	_js_callback_ref = js_callback # สำคัญ! ต้องเก็บใส่ตัวแปรไว้ ไม่งั้นจะโดนลบ
	
	# 2. เข้าถึงตัวแปร window.DiscordBridge ที่เราเขียนไว้ใน HTML
	var win = JavaScriptBridge.get_interface("window")
	var bridge = win.DiscordBridge
	
	# 3. สั่งรันฟังก์ชัน init() ของ JS พร้อมส่ง callback เราไปให้
	if bridge:
		bridge.init(js_callback)
	else:
		printerr("ไม่พบ DiscordBridge ใน HTML Shell")

# ฟังก์ชันนี้จะถูกเรียกโดย JavaScript
func _on_js_message(args):
	# args เป็น Array เสมอ ข้อมูลตัวแรกคือ string ที่ส่งมา
	var json_str = args[0]
	var parse_result = JSON.parse_string(json_str)
	
	if parse_result:
		var type = parse_result.get("type")
		var data = parse_result.get("data")
		
		print("ได้รับข้อความจาก JS: ", type)
		
		match type:
			
			
			#{
			#type: "AUTH_SUCCESS",
			#data: authResult // ตอนนี้มีข้อมูล User ID, Username ให้ Godot ใช้ได้ด้วย!
		  #}
			# data {
  #"access_token": "...",
  #"scopes": ["identify", "rpc.voice.read", ...],
  #"user": {
	#"id": "123456789012345678",
	#"username": "mikegamer",
	#"global_name": "Mike The Traveler",
	#"avatar": "a1b2c3d4e5f6g7h8i9j0"
  #}
			"AUTH_SUCCESS":

				print("[i] ได้รับสัญญาณ AUTH_SUCCESS แล้ว")
				# ส่ง Signal บอกเกมว่าเริ่มได้ หรือส่ง code ไป Backend
				var user_data = data.get("user")
				NetworkMng.my_id = user_data.get("id")
				NetworkMng.username = user_data.get("global_name")
				var _avatar_id = user_data.get("avatar")
				NetworkMng.avatar_url = "https://cdn.discordapp.com/avatars/"+str(NetworkMng.my_id)+"/"+str(_avatar_id)+".png"
				#`https://cdn.discordapp.com/avatars/${userData.id}/${userData.avatar}.png`;
				emit_signal("discord_connected")

			"AUTH_FAILED":
				var err = data.get("error")
				printerr("Discord Error: ", err)
				emit_signal("discord_error", err)
			
			#type: "VOICE_STATE", data: { user_id: event.user_id, is_speaking: true/false} 
			"VOICE_STATE" :
				var _id = data.get("user_id")
				var _isVoicing = data.get("is_speaking")
				print("[i] ได้รับสัญญาณจาก"+_id+" VOICE_STATE : " + str(_isVoicing))
				Global.players.get(str(_id)).setVoicing(_isVoicing)
				NetworkMng._broadcast_playerSpeak(_isVoicing)
