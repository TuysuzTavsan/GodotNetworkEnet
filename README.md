This project is in progress.

Godot Multiplayer proof of concept.
This project aims to demonstrate multiplayer game architecture with minimal setup.
You can explore source code to learn some stuff, or clone the whole project and make some changes to suit your game.
You may or may not use the whole project in release stage. But while developing your dream multiplayer game, you will be in need of multiplayer backends to help you out.
Maybe you need a lobby system to test your dedicated servers. While you decide which backend you should choose, you can use this project as a placeholder.


While this repo is made for an example. This project is not beginner friendly.
If you are just made your way in game networking, I highly suggest to start with simple examples.
While this projects design is minimal, project itself is complex in some ways.

There are 3 seperated folders. Every folder is a seperate godot project. (version 4.2.2)
1-Client: This is what players will use to explore lobbies and play the game.
2-LobbyServer: This project only handles lobbies and starting game sessions.
3-Dedicated Server: This is very similiar to client project in code, but it will manage game and every player. This is your typical authoritave game server.

How it works?
LobbyServer should be running in a port forwarded machine. Every client is free to explore lobbies, chat and start game sessions.
Whenever a game session is started by lobby owner, lobbyServer will launch dedicated server with some arguments passed into it.
These arguments are:
    1-Which port dedicated server should operate?
    2-How many players should be in game and whats their user names.
    3-Whats the ip address of the dedicated server.

    Now its up to you to extend this project to something which lobbyServer deploys dedicated servers on a seperate machine.
    Or you could simply luanch dedicated servers on the same machine with LobbyServer and it would still work pretty much the same.
    This project demonstrates exactly that. In real world multiplayer games, tasks that servers need to handle are seperated into different machines in different locations.
    And there are good reasons for that. This project tries to keep it simple yet realistic in that way.