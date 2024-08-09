extends MarginContainer
class_name PlayerListItem

@onready var m_playerNameLabel : Label = $HBoxContainer/PlayerNameLabel
@onready var m_hostIcon : TextureRect = $HBoxContainer/TextureRect

var m_isLobbyOwner = false
var m_playerName : String = "DefaultPlayerName"

func mInit(playerName : String, isLobbyOwner : bool) -> void:
	m_playerName = playerName
	m_isLobbyOwner = isLobbyOwner

func mUpdateLobbyOwnership(isOwner : bool) -> void:
	if(isOwner):
		m_isLobbyOwner = true
		m_hostIcon.show()
	else:
		m_isLobbyOwner = false
		m_hostIcon.hide()

func _ready() -> void:
	m_playerNameLabel.text = m_playerName

	if(not m_isLobbyOwner):
		m_hostIcon.hide()