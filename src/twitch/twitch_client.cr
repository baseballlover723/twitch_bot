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
      resp = get_validate
      raise InvalidConfigException.new(resp.body) unless resp.success?
    end

    private def get_validate : HTTP::Client::Response
      resp = get("https://id.twitch.tv/oauth2/validate", headers: HTTP::Headers{"Authorization" => "OAuth #{@config.token.access_token}"})
      puts "#{@config.username} token is #{resp.success? ? "" : "not "}valid"
      resp
    end

    def get_user(username : String) : User
      resp = get("https://api.twitch.tv/helix/users", query_params: {login: username})
      data = NamedTuple(data: Array(User)).from_json(resp.body)
      data[:data][0]
    end

    def get_chatters(broadcaster_id : String) : Array(String)
      resp = get("https://api.twitch.tv/helix/chat/chatters", query_params: {broadcaster_id: broadcaster_id, moderator_id: @bot_user.id})
      data = NamedTuple(data: Array(Chatter)).from_json(resp.body)
      data[:data].map { |chatter| chatter.user_name }
    end

    {% for method in %w(get post put patch delete) %}
    {% has_body = !%w(get delete).includes?(method) %}
      def {{method.id}}(
        url : String,
        query_params : (Hash(String, String) | NamedTuple)? = nil,
        headers : HTTP::Headers = HTTP::Headers{"Authorization" => "Bearer #{@config.token.access_token}", "Client-Id" => @config.client_id},
        {% if has_body %}
          body : (Hash | NamedTuple)? = nil,
        {% end %}
      ) : HTTP::Client::Response
        url = "#{url}?#{URI::Params.encode(query_params)}" if !!query_params && !query_params.empty?
        {% if has_body %}
          headers = headers.add("Content-Type", "application/json") if !!body && !body.empty?
          resp = HTTP::Client.{{method.id}}(url, headers: headers, body: body.to_json)
        {% else %}
          resp = HTTP::Client.{{method.id}}(url, headers: headers)
        {% end %}
        puts resp.inspect unless resp.success?
        resp
      end
    {% end %}
  end
end
