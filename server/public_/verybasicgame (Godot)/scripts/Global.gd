extends Node

var players:Dictionary = {} # ID , playerObj

func getOnlinePlayer(): # include this client
	var count:int = 0
	for _playerId in players.keys() :
		if players[_playerId] : count += 1
	return count

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
