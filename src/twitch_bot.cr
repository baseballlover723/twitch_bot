require "./twitch/config"

module TwitchBot
  VERSION = "0.1.0"
end

Config.instance

puts "config: #{Config.instance.inspect}"
