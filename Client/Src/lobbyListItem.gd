extends MarginContainer
class_name LobbyListItem

#LobbyListItem to help show player current lobbies.

@onready var m_lobbyNameLabel : Label = $HBoxContainer/LobbyNameLabel
@onready var m_playerCountLabel : Label = $HBoxContainer/PlayerCountLabel
@onready var m_statusLabel : Label = $HBoxContainer/StatusLabel
@onready var m_joinButton : Button = $HBoxContainer/JoinButton

var m_lobbyName : String = ""
var m_playerCount : int = -1
var m_capacity : int = -1
var m_isSealed : bool = false


signal _m_JoinPressed(lobbyListItem : LobbyListItem)

func _ready() -> void:
	m_lobbyNameLabel.text = m_lobbyName
	m_playerCountLabel.text = str(m_playerCount) + "/" + str(m_capacity)
	m_statusLabel.text = "open" if not m_isSealed else "sealed"
	
	if(m_isSealed):
		m_joinButton.disabled = true


func mInit(lobbyName : String, playerCount : int, capacity : int, isSealed : bool) -> void:
	m_lobbyName = lobbyName
	m_playerCount = playerCount
	m_capacity = capacity
	m_isSealed = isSealed

func _onJoinPressed() -> void:
	_m_JoinPressed.emit(self)
