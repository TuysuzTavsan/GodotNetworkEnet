extends MarginContainer
class_name PlayerListItem

@onready var m_playerNameLabel : Label = $HBoxContainer/PlayerNameLabel
@onready var m_hostIcon : TextureRect = $HBoxContainer/TextureRect

var m_isHost = false
var m_playerName : String = "DefaultPlayerName"

func mInit(playerName : String, isHost : bool) -> void:
	m_playerName = playerName
	m_isHost = isHost

func _ready() -> void:
	m_playerNameLabel.text = m_playerName

	if(not m_isHost):
		m_hostIcon.hide()