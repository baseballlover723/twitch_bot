require "./twitch/twitch_client"
# require "./irc_server"
# require "./websocket_server"

require "./twitch_bot"

Signal::INT.trap do
  puts "disconnecting from active twitch channels"
  TwitchBot.active_servers.each { |server| server.stop }
  exit
end

enable_2nd = ARGV.shift? == "true"

# TODO doesn't work gets a 403 forbidden when trying to subscribe to event sub
# twitch_client = Twitch::Client.new("baseballlover723_bot")
twitch_client = Twitch::Client.new("baseballlover723")
# user = twitch_client.get_user("baseballlover723")
# puts "user: #{user}"
# puts "chatters: #{twitch_client.get_chatters(user.id)}"
# twitch_client.post_create_eventsub("channel.channel_points_custom_reward_redemption.add", "1", {broadcaster_user_id: user.id}, "secret")

twitch_bot = TwitchBot.new(twitch_client, "baseballlover723")
twitch_bot2 = uninitialized TwitchBot
if enable_2nd
  twitch_bot2 = TwitchBot.new(twitch_client, "doomerdinger")
end

twitch_bot.start
if enable_2nd
  twitch_bot2.start
end

TwitchBot.wait_for_servers_to_disconnect

# irc_server = IRC_Server.new(twitch_client, "baseballlover723")
# irc_server2 = uninitialized IRC_Server
# if enable_2nd
#   irc_server2 = IRC_Server.new(twitch_client, "doomerdinger")
# end

# # spawn do
# #   sleep 50
# #   IRC_Server.active_servers.each { |server| server.stop }
# # end

# puts "starting irc server 1"
# irc_server.start
# puts "started irc server 1"
# if enable_2nd
#   puts "starting irc server 2"
#   irc_server2.start
#   puts "started irc server 2"
# end

# websocket_server = Websocket_Server.new(twitch_client, irc_server)
# websocket_server2 = uninitialized Websocket_Server
# if enable_2nd
#   websocket_server2 = Websocket_Server.new(twitch_client, irc_server2)
# end
# puts "starting websocket server 1"
# websocket_server.start
# puts "started websocket server 1"
# if enable_2nd
#   puts "starting websocket server 2"
#   websocket_server2.start
#   puts "started websocket server 2"
# end

# puts "waiting for servers to shutdown later"
# IRC_Server.wait_for_servers_to_disconnect
# # puts "waiting for servers to shutdown later"
# Websocket_Server.wait_for_servers_to_disconnect
