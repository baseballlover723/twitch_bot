require "http/client"

require "./config"
require "./config/invalid_config_exception"

module Twitch
  class Client
    getter config : Config

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
    end

    def validate : Bool
      get_validate.success?
    end

    def validate! : Nil
      validate_resp = get_validate
      raise InvalidConfigException.new(validate_resp.body) unless validate_resp.success?
    end

    private def get_validate
      validate_url = "https://id.twitch.tv/oauth2/validate"
      validate_resp = HTTP::Client.get(validate_url, headers: HTTP::Headers{"Authorization" => "OAuth #{@config.token.access_token}"})
      puts "#{@config.username} token is #{validate_resp.success? ? "" : "not "}valid"
      validate_resp
    end
  end
end
