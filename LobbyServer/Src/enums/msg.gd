class_name Msg
 
# This enum allow us to communicate to lobbyServer.
# LobbyServer also uses the same enum.
# For better readability i used *feedback enums.
# You dont really need seperate enums for feedbacks.
# If a client sends join_lobby request to lobbyServer.
# LobbyServer will know its coming from client.
# Similiarly, if LobbyServer sends client join_lobby msg.
# Client will not its feedback.
# But i choose readability over complexity.

#We send packets as
# {Msg.Type} {data}
# Every enum type has some different data structure.
# Depending on the enum. Data means differnt results.
# For example for enum NEW_LOBBY_FEEDBACK : 
    # if Data is 0 it means lobby can not created because lobby name is taken.
    # if Data is 1 it means lobby is successfully created.
# You can check how Client excepts data to be in CLient project.

enum Type
{
UNSPECIFIED = 0,                #Never used.
USER_INFO = 1,                  #Send userName to server.
LOBBY_LIST = 2,                 #Request lobbyList from server.
PLAYER_LIST = 3,                #Request playerList from server. (lobby)
NEW_LOBBY = 4,                  #Request new lobby from server.
JOIN_LOBBY = 5,                 #Request to join lobby from server.
LEFT_LOBBY = 6,                 #Inform server that user left.
                                    #WARNING if this msg comes from lobbyserver.
                                    #It means lobbyServer is kicking *this client from lobby.
LOBBY_MESSAGE = 7,              #Inform server that chat msg is sent.
READY = 8,                      #Inform server that ready status is changed in lobby.
                                #
                                # data is = {
                                #   "isReady" : isReady 
                                #   }
                                #
START_GAME = 9,                 #Request server to start game.
                                # if msg comes from server, it means owner of the lobby started the game.
                                # This is used for scene management in client project.
                                # data is {
                                # "inSeconds" : int
                                #}


USER_INFO_FEEDBACK = 10,         #Server feedback to USER_INFO. Will be used to set player name on client.
LOBBY_LIST_FEEDBACK = 11,        #Server sent lobby list.
                                        #
                                        #   data is array of dictionaries.
                                        #   dictionaries are = {
                                        #   "lobbyName" : name,
                                        #   "playerCount" : playerCount,
                                        #   "capacity" : capacity,
                                        #   "isSealed" : isSealed
                                        #   }
                                        #
PLAYER_LIST_FEEDBACK = 12,       #Server sent playerlist for lobby.
                                        #
                                        #   data is array of dictionaries.
                                        #   dictionaries are = {
                                        #   "userName" : name,
                                        #   "isHost" : isHost
                                        #   "isReady" : isReady
                                        #   }

NEW_LOBBY_FEEDBACK = 13,        #Server feedback to new lobby request.
                                    #if data is 0: Failed to create new lobby, name is already taken.
                                    #if data is 1: successfully created lobby.
JOIN_LOBBY_FEEDBACK = 14,       #Server feedback to join lobby request.
                                    #if data is 0: Failed to join lobby. No lobby found with name.
                                    #if data is 1: Successfully joined the lobby.
                                    #if data is 2: Failed to join lobby. Capacity is full.
                                    #if data is 3: Failed to join lobby. Lobby is sealed.
                                    #if another player joined lobby while currently in lobby.
                                        #data is = {
                                        # "userName" : name,
                                        #}
LEFT_LOBBY_FEEDBACK = 15,       #Server informing another user left lobby.
                                    #if data is 3: Lobby is deleted due to timeout.
LOBBY_MESSAGE_FEEDBACK = 16,    #Server informing another user sent msg.
                                    #
                                    # data is = {
                                    # "userName" : name,
                                    # "msg" : msg
                                    #}
                                    #
HOST_FEEDBACK = 17,             #Server informing owner of the lobby is changed.
                                    #data is = { 
                                    # "userName" : name,
                                    # "isHost" : isHost
                                    #}
READY_FEEDBACK = 18,            #Server informing another player's ready status is changed.
                                    #   data is = {
                                    #   "userName" : userName,
                                    #   "isReady" : isReady
                                    #   }
START_GAME_FEEDBACK = 19        #Server feedback to player if the game is starting.
                                    #   data is = {
                                    #   "code" : int,
                                    #   "port" : port to connect,
                                    #   "inSeconds" : inSeconds (only available when code is 3)
                                    #   }
                                    #
                                    # if code is 0 it means something interrupted the process, maybe someone left lobby or not ready.
                                    # if code is 1 it means server started succesfully on port.
                                    # if code is 2 it means server faied to start.
                                    # if code is 3 it means feedback about time value for the owner.

}