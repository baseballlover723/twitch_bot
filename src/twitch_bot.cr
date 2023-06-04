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
# twitch_client.post_create_eventsub("channel.channel_points_custom_reward_redemption.add", "1", {broadcaster_user_id: user.id}, "secret")

irc_server = IRC_Server.new(twitch_client, "baseballlover723")
irc_server2 = IRC_Server.new(twitch_client, "doomerdinger")

# spawn do
#   sleep 50
#   IRC_Server.active_servers.each { |server| server.stop }
# end

puts "starting irc server 1"
irc_server.start
puts "started irc server 1"
puts "starting irc server 2"
irc_server2.start
puts "started irc server 2"

websocket_server = Websocket_Server.new(twitch_client, irc_server)
websocket_server2 = Websocket_Server.new(twitch_client, irc_server2)
puts "starting websocket server 1"
websocket_server.start
puts "started websocket server 1"
puts "starting websocket server 2"
websocket_server2.start
puts "started websocket server 2"

puts "waiting for servers to shutdown later"
IRC_Server.wait_for_servers_to_disconnect
# puts "waiting for servers to shutdown later"
Websocket_Server.wait_for_servers_to_disconnect
