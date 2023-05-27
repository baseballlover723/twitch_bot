require "./twitch/config"

module TwitchBot
  VERSION = "0.1.0"
end

Config.instance

puts "config: #{Config.instance.inspect}"

Config.instance.refresh_token!

puts "config: #{Config.instance.inspect}"
