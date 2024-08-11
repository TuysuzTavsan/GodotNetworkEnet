extends MarginContainer
class_name PlayerListItem

@onready var m_playerNameLabel : Label = $HBoxContainer/PlayerNameLabel
@onready var m_hostIcon : TextureRect = $HBoxContainer/TextureRect
@onready var m_readyButton : Button = $HBoxContainer/ReadyButton

var m_isLobbyOwner = false
var m_playerName : String = "DefaultPlayerName"
var m_isReady : bool = false

func mInit(playerName : String, isLobbyOwner : bool, isReady : bool) -> void:
	m_playerName = playerName
	m_isLobbyOwner = isLobbyOwner
	m_isReady = isReady

func mUpdateLobbyOwnership(isOwner : bool) -> void:
	if(isOwner):
		m_isLobbyOwner = true
		m_hostIcon.show()
	else:
		m_isLobbyOwner = false
		m_hostIcon.hide()

func mUpdateReadyState(isReady : bool) -> void:
	m_isReady = isReady
	m_readyButton.button_pressed = isReady
	m_readyButton.self_modulate = Color.GREEN if m_isReady else Color.WHITE

func _ready() -> void:
	m_playerNameLabel.text = m_playerName
	m_readyButton.button_pressed = m_isReady
	m_readyButton.self_modulate = Color.GREEN if m_isReady else Color.WHITE
	if(not m_isLobbyOwner):
		m_hostIcon.hide()
	
	if(Client.m_userName == m_playerName):
		m_readyButton.disabled = false
	else:
		m_readyButton.disabled = true

func _onReadyToggled(toggled_on:bool) -> void:
	m_readyButton.self_modulate = Color.GREEN if toggled_on else Color.WHITE
	m_isReady = toggled_on

	var dictToSend : Dictionary = {
		"isReady" : toggled_on
	}

	Client.mSendPacket(Msg.Type.READY, dictToSend)
