require "./token"
require "./web_server"

class Config
  TOKEN_PATH = "./secrets/token.json"
  SCOPE      = Set{
    "channel:edit:commercial",
    "channel:manage:polls",
    "moderator:manage:banned_users",
    "moderator:manage:chat_messages",
    "moderator:manage:chat_settings",
    "moderator:read:chatters",
  }

  getter client_id : String
  getter client_secret : String
  property token : Token

  private def initialize
    hash = NamedTuple(client_id: String, client_secret: String).from_json({{read_file("./secrets/secrets.json")}})
    @client_id = hash[:client_id]
    @client_secret = hash[:client_secret]
    @token = Token.load(TOKEN_PATH) || Token.generate(TOKEN_PATH, SCOPE, @client_id, @client_secret)
  end

  def self.instance
    @@instance ||= new
  end

  def refresh_token! : Nil
    @token = Token.refresh(TOKEN_PATH, @client_id, @client_secret, @token)
  end
end
