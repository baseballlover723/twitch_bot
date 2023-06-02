require "json"
require "http/web_socket"

require "./twitch/twitch_client"

# TODO combine with irc server? into twitch chat class? or need to interface things to bubble back up and shit
class Websocket_Server
  @@servers = Set(Websocket_Server).new

  getter twitch_client : Twitch::Client
  getter irc_server : IRC_Server
  @connected : Bool
  @joined : Bool
  @joined_channel : Channel(Nil)

  def initialize(@twitch_client : Twitch::Client, @irc_server : IRC_Server)
    @connected = false
    @joined = false
    @websocket_client = HTTP::WebSocket.new(URI.parse("wss://eventsub.wss.twitch.tv/ws"))
    @joined_channel = Channel(Nil).new
    setup_actions

    @@servers << self
  end

  def finalize
    @@servers.delete(self)
  end

  def self.wait_for_servers_to_disconnect
    while @@servers.any? { |server| server.connected? }
      sleep 0.1
    end
  end

  def self.active_servers
    @@servers.select { |server| server.connected? }
  end

  def connected? : Bool
    @connected
  end

  def joined? : Bool
    @joined
  end

  def start
    @connected = true
    spawn do
      @websocket_client.run
    end
    @joined_channel.receive
  end

  def stop
    puts "stopping websocket for #{@irc_server.channel}"
    @websocket_client.close
    @connected = false
  end

  alias WelcomeMessage = NamedTuple(metadata: NamedTuple(message_id: String, message_type: String, message_timestamp: Time), payload: NamedTuple(session: NamedTuple(id: String, status: String, connected_at: Time, keepalive_timeout_seconds: Int32, reconnect_url: String?)))

  # TODO put commands into their own files
  # TODO support only having some commands
  private def setup_actions
    welcome_message = uninitialized WelcomeMessage
    @websocket_client.on_close do |close_code, msg|
      puts "twitched closed websocket: #{msg} (#{close_code})"
      stop
    end
    @websocket_client.on_ping do |msg|
      puts "recieved ping: #{msg}"
      @websocket_client.pong(msg)
    end
    @websocket_client.on_message do |msg|
      puts "message recieved (welcome): #{msg}"
      welcome_message = WelcomeMessage.from_json(msg)
      @websocket_client.on_message(&->handle_message(String))
      setup_subs(welcome_message[:payload][:session][:id])
      @joined = true
      @joined_channel.send(nil)
      @irc_server.send_message("setup websocket")
    end
  end

  private def setup_subs(session_id : String)
    @twitch_client.post_create_eventsub("channel.channel_points_custom_reward_redemption.add", "1", {broadcaster_user_id: @irc_server.channel_user.id}, session_id)
  end

  private def handle_message(msg_str : String)
    puts "message recieved:"
    msg = JSON.parse(msg_str)
    puts msg
    case msg["metadata"]["message_type"]
    when "session_keepalive"
      puts "TODO keepalive message"
    when "session_reconnect"
      puts "TODO reconnect"
    when "notification"
      puts "notification message"
    end
  end
end
