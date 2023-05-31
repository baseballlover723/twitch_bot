require "crirc"

require "./twitch/twitch_client"

# TODO send part when leaving?
class IRC_Server
  @@servers = Set(IRC_Server).new

  getter twitch_client : Twitch::Client
  getter channel : String
  @connected : Bool

  def initialize(@twitch_client : Twitch::Client, channel : String)
    @connected = false
    @channel = channel.starts_with?('#') ? channel : "##{channel}"
    @irc_client = Crirc::Network::Client.new nick: @twitch_client.config.username,
      ip: "irc.chat.twitch.tv",
      port: 6697,
      ssl: true,
      pass: "oauth:#{@twitch_client.config.token.access_token}"
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

  def start
    @connected = true
    @irc_client.connect
    # @irc_client.puts("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands")
    @irc_client.puts("CAP REQ :twitch.tv/membership twitch.tv/commands")
    @irc_client.start(&->while_connected(Crirc::Controller::Client))
  end

  def stop
    puts "stopping irc for #{@channel}"
    # @irc_client.puts("PART #{@channel}")
    @irc_client.close
    @connected = false
  end

  private def while_connected(bot : Crirc::Controller::Client)
    bot.on_ready do
      puts "bot is ready"
      bot.join Crirc::Protocol::Chan.new(@channel)
      puts "joined #{@channel}"
    end.on("PING") do |msg|
      bot.pong(msg.message)
    end.on("PRIVMSG") do |msg|
      username = parse_username(msg)
      puts "got message from \"#{username}\": \"#{msg.message}\" in \"#{msg.arguments}\""
    end

    spawn do
      loop do
        begin
          m = bot.gets
          break if m.nil?
          puts "[#{Time.local}] #{m}"
          spawn { bot.handle(m.as(String)) }
        rescue IO::TimeoutError
          puts "Nothing happened..."
        end
      end
    end
  end

  private def parse_username(msg : Crirc::Protocol::Message) : String
    msg.source[0...msg.source.index('!')]
  end
end
