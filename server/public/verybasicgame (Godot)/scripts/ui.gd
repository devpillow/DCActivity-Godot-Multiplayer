extends CanvasLayer

@export var ErrorDisplayer:ColorRect
@export var SoundSetting:Control

func _on_soundSetting_button_up() -> void:
	SoundSetting.showSoundSetting()
