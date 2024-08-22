extends Node

#Singleton to play music across scenes.

@onready var m_menuMusicPlayer : AudioStreamPlayer = $MenuMusicPlayer

func _mPlayMenuMusic() -> void:
	m_menuMusicPlayer.play()
