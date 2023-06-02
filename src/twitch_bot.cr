require "./twitch/twitch_client"
require "./irc_server"
require "./websocket_server"

module TwitchBot
  VERSION = "0.1.0"
end

Signal::INT.trap do
  puts "disconnecting from active irc / websocket servers"
  IRC_Server.active_servers.each { |server| server.stop }
  Websocket_Server.active_servers.each { |server| server.stop }
  exit
end

twitch_client = Twitch::Client.new("baseballlover723")
# user = twitch_client.get_user("baseballlover723")
# puts "user: #{user}"
# puts "chatters: #{twitch_client.get_chatters(user.id)}"
irc_server = IRC_Server.new(twitch_client, "baseballlover723")
# irc_server2 = IRC_Server.new(twitch_client, "doomerdinger")

# spawn do
#   sleep 50
#   IRC_Server.active_servers.each { |server| server.stop }
# end

puts "starting server 1"
irc_server.start
puts "started server 1"
# puts "starting server 2"
# irc_server2.start
# puts "started server 2"

websocket_server = Websocket_Server.new(twitch_client, irc_server)
puts "starting server 1"
websocket_server.start
puts "started server 1"

puts "waiting for servers to shutdown later"
IRC_Server.wait_for_servers_to_disconnect
# puts "waiting for servers to shutdown later"
Websocket_Server.wait_for_servers_to_disconnect
