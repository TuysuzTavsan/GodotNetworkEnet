
# Standalone Godot Multiplayer Proof of Concept.
- This project aims to demonstrate multiplayer game architecture with minimal setup.
Also a proof of concept for me to test my skills.
You can explore source code to learn some stuff, clone project and make some changes, or playtest it.
You can also use lobbyServer for your project. Maybe you need a lobby or matchmaking system to test your dedicated servers.
While you decide which backend you should choose, you can use this project as a placeholder.
Or you can start to write your solutions. Until then LobbyServer might help you out (a bit).

<p align="center">
  <img src="https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExYzFoaTdvZjAwZDc0bm41Z3Z6amNkbWk1cmJ5aGlpd3F0ZDdsN253aiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/WsjNQeS6MLhEsxXRHF/giphy.webp" width="350"/>
  <img src="https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExNWlqenlva29vaHhoajZ4YjVrcng2emo4anhiMXFvaTZ3eDcyY3M0NiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/O8qlZDH6OQKU6pT0n3/giphy.webp" width="350"/>
</p>

## Youtube showcase link -> https://youtu.be/etoccA7Z-Rk

> [!IMPORTANT]
> While this repo is made for an example. This project is not beginner friendly.
> If you are just made your way in game networking, I highly suggest to start with simple examples.
> While this projects design is minimal, project itself is complex in many ways.


 There are 3 seperated folders. Every folder is a seperate godot project. (Godot Engine Version 4.3)
- 1-Client: This is what players will use to explore lobbies and play the game.
- 2-LobbyServer: This project only handles lobbies and starting game sessions. Networking is low level with Enet.
- 3-Dedicated Server: This is very similiar to client project in code, but it will manage game and every player. This is your typical authoritave game server. Networking is made with high level godot rpc system

# How it works?
LobbyServer should be running in a port forwarded machine. Every client is free to explore lobbies, chat and start game sessions.
Whenever a game session is started by lobby owner, lobbyServer will launch dedicated server with some arguments passed into it.
These arguments are:

- 1-Which port dedicated server should operate?
- 2-How many players should be in game.
- 3-Whats the ip address of the dedicated server.

 After that specific lobby will be freed and clients will try to connect gameServer on given port.

# Minimal Project Setup.
 You can test locally, or on vds vps, dedicated server.
- 1- Change IP Addresses & ports on LobbyServer/Client project. (in LobbyServer constants are located in host.gd, in Client constants are located in client.gd)
- 2- Change gameServer absolute path to your taste.
- 3- Export projects for your desired system.
- 4- On server machine, open ports in range (7000-9999 as default but you can change port range on host.gd). Also check firewall.
- 5- Place GameServer in matching absolute directory that you set in step 2.
- 5- Run LobbyServer.
- 6- Now you should be able to connect from client project and play. If not, double check IP adresses / ports / gameServer absolute path.

> [!NOTE]
> Now its up to you to extend this project to something which lobbyServer deploys dedicated servers on a seperate machine.
> Or you could simply luanch dedicated servers on the same machine with LobbyServer and it would still work pretty much the same.
> This project demonstrates exactly that. In real world multiplayer games, tasks that servers need to handle are seperated into different machines in different locations.
> And there are good reasons for that. This project tries to keep it simple yet realistic in that way.

> [!IMPORTANT]
> I do not own any assets used in this project. Thanks for making these assets and sharing them.
> - 1-https://pixelfrog-assets.itch.io/tiny-swords
> - 2-https://pixelfrog-assets.itch.io/pirate-bomb
> - 3-https://seartsy.itch.io/free-pirate
> - 4-https://coffeevalenbat.itch.io/sweet-sounds-sfx-pack
> - 5-https://opengameart.org/content/library-of-game-sounds
> - 6-https://alkakrab.itch.io/free-pirate-game-music-pack
> - 7-https://kenney.nl/assets/ui-audio
