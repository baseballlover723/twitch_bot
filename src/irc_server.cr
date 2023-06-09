require "crirc"

require "./twitch_bot"
require "./twitch/twitch_client"

# TODO send part when leaving?
# TODO figure out why it doesn't always start, and have it block until it joins channel i think?
class IRC_Server
  MAX_GUESS_NUMB = 25

  @@servers = Set(IRC_Server).new

  getter twitch_client : Twitch::Client
  getter channel : String
  getter channel_user : Twitch::User
  @connected : Bool
  @joined : Bool
  @joined_channel : Channel(Nil)

  def initialize(@twitch_client : Twitch::Client, channel : String)
    @connected = false
    @joined = false
    @channel = channel.starts_with?('#') ? channel : "##{channel}"
    @channel_user = @twitch_client.get_user(@channel[1..-1])
    @irc_client = Crirc::Network::Client.new nick: @twitch_client.config.username,
      ip: "irc.chat.twitch.tv",
      port: 6697,
      ssl: true,
      pass: "oauth:#{@twitch_client.config.token.access_token}"
    @joined_channel = Channel(Nil).new
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
    @irc_client.connect
    # @irc_client.puts("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands")
    @irc_client.puts("CAP REQ :twitch.tv/membership twitch.tv/commands")
    @irc_client.start(&->while_connected(Crirc::Controller::Client))
    @joined_channel.receive
  end

  def stop
    puts "stopping irc for #{@channel}"
    # @irc_client.puts("PART #{@channel}")
    @irc_client.close
    @joined = false
    @connected = false
  end

  # TODO put commands into their own files
  # TODO support only having some commands
  private def while_connected(bot : Crirc::Controller::Client)
    numb_to_guess = Random.rand(MAX_GUESS_NUMB)
    previous_guesses = Set(Int32).new
    bot.on_ready do
      puts "bot is ready"
      bot.join Crirc::Protocol::Chan.new(@channel)
      @joined = true
      @joined_channel.send(nil)
      send_message("Bot is ready")
      puts "joined #{@channel}"
    end.on("PING") do |msg|
      bot.pong(msg.message)
    end.on("PRIVMSG") do |msg|
      sleep 2 unless @channel == "#baseballlover723"
      username = parse_username(msg)
      puts "got message from \"#{username}\": \"#{msg.message}\" in \"#{msg.arguments}\""
      case msg.message
      when "!version"
        bot.reply msg, "baseballlover723's bot version: #{TwitchBot::VERSION}"
      when "!ping"
        bot.reply msg, "pong"
      when /\!d\d+/
        max = msg.message.as(String)[/\d+/].to_i
        if max == 0
          bot.reply msg, "How the fuck am I supposed to roll a 0 sided dice?????"
        else
          bot.reply msg, "Rolled a #{max} sided dice and got: #{Random.rand(max) + 1}"
        end
      when /\!guess \d+$/
        guess = msg.message.as(String)[/\d+/].to_i
        if guess <= 0 || guess > MAX_GUESS_NUMB
          bot.reply msg, "Please guess an integer from 1 to #{MAX_GUESS_NUMB}"
        else
          if guess == numb_to_guess
            username = parse_username(msg)
            bot.reply msg, "Congragulations, #{username} guessed the correct integer (#{numb_to_guess})"
            previous_guesses.clear
            numb_to_guess = Random.rand(MAX_GUESS_NUMB)
          elsif (previous_guesses.includes?(guess))
            bot.reply msg, "Sorry, #{guess} has already been guessed, please try again. previous guesses: #{previous_guesses.to_a.sort}"
          else
            previous_guesses << guess
            bot.reply msg, "Sorry your guess of #{guess} was incorrect, please try again. previous guesses: #{previous_guesses.to_a.sort}"
          end
        end
      when /\!guess cheat/
        username = parse_username(msg).downcase
        # puts "username: #{username}, channel_user: #{channel_user.inspect}"
        next unless username == channel_user.login
        bot.reply msg, "Congragulations, #{username} guessed the correct integer (#{numb_to_guess})"
        previous_guesses.clear
        numb_to_guess = Random.rand(MAX_GUESS_NUMB)
      when /\!guess/
        bot.reply msg, "Please guess an integer from 1 to #{MAX_GUESS_NUMB}"
      when "!list_users"
        chatters = @twitch_client.get_chatters(@channel_user.id)
        bot.reply msg, "current chatters: [#{chatters.join(", ")}]"
      end
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

  def send_message(msg : String) : Nil
    @irc_client.puts("PRIVMSG #{@channel} :#{msg}")
  end
end
