extends Node2D
class_name MainWorld

@export var playerPref:PackedScene

@export var Ui:CanvasLayer

func spawnPlayer(_id:String,_name:String ,_pos:Vector2) -> Player:
	
	var player_inst:Player = playerPref.instantiate()
	add_child(player_inst)
	player_inst.position = _pos
	player_inst.player_id = _id
	player_inst.set_nickname(_name)
	Global.players[str(_id)] = player_inst
	
	if player_inst.player_id == NetworkMng.my_id :
		print("สร้างตัวเองขึ้นมาแล้ว")
	return player_inst
