require "http/client"

require "./config"

module Twitch
  class Client
    getter config : Config

    def initialize(username : String)
      @config = Config.new(username)
      validate
    end

    def initialize(username : String, token_directory : String)
      @config = Config.new(username, token_directory)
      validate
    end

    def validate : Bool
      validate_url = "https://id.twitch.tv/oauth2/validate"

      validate_resp = HTTP::Client.get(validate_url, headers: HTTP::Headers{"Authorization" => "OAuth #{@config.token.access_token}"})
      puts "#{@config.username} token is #{validate_resp.success? ? "" : "not "}valid"
      puts "validate_resp: #{validate_resp.inspect}" unless validate_resp.success?
      validate_resp.success?
    end
  end
end
