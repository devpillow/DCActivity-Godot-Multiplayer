extends Control

#@onready var VolumnSlider = $VolumnSlider
@onready var bgMusic = $AudioStreamPlayer
@onready var BGMslider = $VolumnSlider
func showSoundSetting() :
	if self.visible : self.hide()
	else : self.show()

func _ready() -> void:
	BGMslider.value = db_to_linear(-30)

func _on_volumn_slider_value_changed(value: float) -> void:
	#print("CHANING")
	var bus_index = AudioServer.get_bus_index("BGM")
	# 2. ปรับความดังโดยแปลงค่าจาก Slider (0-1) เป็น Decibel
	var db_volume = linear_to_db(value)
	# 3. สั่งงาน AudioServer
	AudioServer.set_bus_volume_db(bus_index, db_volume)
	# (Option) ถ้าลากจนสุด ให้ Mute ไปเลยเพื่อประหยัดทรัพยากร
	AudioServer.set_bus_mute(bus_index, value < 0.01)


var SoundSettingCD = 0.4
var SoundSettingleft = 0
func _input(event: InputEvent) -> void:
	if Input.is_action_pressed('SoundSetting') and SoundSettingleft == 0 : 
		showSoundSetting()
		SoundSettingleft = SoundSettingCD

func _physics_process(delta: float) -> void:
	if SoundSettingleft >0 :
		SoundSettingleft -= delta
		if SoundSettingleft <0:
			SoundSettingleft =0 
	
