require "./twitch/twitch_client"
require "./irc_server"
require "./websocket_server"

class TwitchBot
  VERSION = "0.1.0"
  @@servers = Set(TwitchBot).new

  getter twitch_client : Twitch::Client
  getter channel_username : String
  getter channel : String
  getter channel_user : Twitch::User

  def initialize(@twitch_client : Twitch::Client, @channel_username : String)
    if @channel_username.starts_with?('#')
      @channel = @channel_username
      @channel_username = @channel_username[1..-1]
    else
      @channel = "##{@channel_username}"
    end
    @channel_user = @twitch_client.get_user(@channel_username)
    @irc_server = IRC_Server.new(@twitch_client, "baseballlover723")
    @websocket_server = Websocket_Server.new(@twitch_client, @irc_server)

    @@servers << self
  end

  def finalize
    @@servers.delete(self)
  end

  def self.wait_for_servers_to_disconnect
    IRC_Server.wait_for_servers_to_disconnect
    Websocket_Server.wait_for_servers_to_disconnect
  end

  def self.active_servers
    @@servers.select { |server| server.connected? }
  end

  def connected? : Bool
    @irc_server.connected? || @websocket_server.connected?
  end


  def start
    puts "starting twitch bot for #{@channel}"
    @irc_server.start
    @websocket_server.start
  end

  def stop
    puts "stopping twitch bot for #{@channel}"
    done_channel = Channel(Nil).new
    spawn do
      @irc_server.stop
      done_channel.send(nil)
    end
    spawn do
      @websocket_server.stop
      done_channel.send(nil)
    end
    done_channel.receive
    done_channel.receive
  end
end
