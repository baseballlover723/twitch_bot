require "./config/token"

module Twitch
  class Config
    DEFAULT_TOKEN_DIRECTORY = "./secrets"
    SCOPE                   = Set{
      "channel:edit:commercial",
      "channel:manage:polls",
      "chat:edit",
      "chat:read",
      "channel:moderate",
      "channel:read:redemptions",
      "channel:read:subscriptions",
      "moderator:manage:banned_users",
      "moderator:manage:chat_messages",
      "moderator:manage:chat_settings",
      "moderator:read:chatters",
    }

    getter username : String
    getter client_id : String
    getter client_secret : String
    getter token_path : String
    property token : Token

    def initialize(@username : String, token_directory : String = DEFAULT_TOKEN_DIRECTORY)
      @client_id = {{read_file("./secrets/.client_id")}}
      @client_secret = {{read_file("./secrets/.client_secret")}}
      @token_path = File.join(token_directory, @username, "token.json")
      @token = Token.load(@username, @token_path) || Token.generate(@username, @token_path, SCOPE, @client_id, @client_secret)
    end

    def refresh_token! : Nil
      @token = Token.refresh(@username, @token_path, @client_id, @client_secret, @token)
    end
  end
end
