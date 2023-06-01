require "http/client"

require "./config"
require "./config/invalid_config_exception"

require "./dto/*"

module Twitch
  class Client
    getter config : Config
    getter bot_user : User

    def initialize(username : String)
      initialize(Config.new(username))
    end

    def initialize(username : String, token_directory : String)
      initialize(Config.new(username, token_directory))
    end

    def initialize(@config : Config)
      if !validate
        @config.refresh_token!
        validate!
      end
      @bot_user = get_user(@config.username)
    end

    def validate : Bool
      get_validate.success?
    end

    def validate! : Nil
      validate_resp = get_validate
      raise InvalidConfigException.new(validate_resp.body) unless validate_resp.success?
    end

    def get_user(username : String) : User
      query_params = {login: username}
      url = "https://api.twitch.tv/helix/users?#{URI::Params.encode(query_params)}"
      resp = HTTP::Client.get(url, headers: HTTP::Headers{"Authorization" => "Bearer #{@config.token.access_token}", "Client-Id" => @config.client_id})
      data = NamedTuple(data: Array(User)).from_json(resp.body)
      data[:data][0]
    end

    def get_chatters(broadcaster_id : String) : Array(String)
      query_params = {
        broadcaster_id: broadcaster_id,
        moderator_id:   @bot_user.id,
      }
      chatter_url = "https://api.twitch.tv/helix/chat/chatters?#{URI::Params.encode(query_params)}"
      resp = HTTP::Client.get(chatter_url, headers: HTTP::Headers{"Authorization" => "Bearer #{@config.token.access_token}", "Client-Id" => @config.client_id})
      data = NamedTuple(data: Array(Chatter)).from_json(resp.body)
      data[:data].map {|chatter| chatter.user_name}
    end

    private def get_validate
      validate_url = "https://id.twitch.tv/oauth2/validate"
      validate_resp = HTTP::Client.get(validate_url, headers: HTTP::Headers{"Authorization" => "OAuth #{@config.token.access_token}"})
      puts "#{@config.username} token is #{validate_resp.success? ? "" : "not "}valid"
      validate_resp
    end
  end
end
