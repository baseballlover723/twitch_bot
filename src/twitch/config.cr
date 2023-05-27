require "./token"
require "./web_server"

class Config
  TOKEN_PATH = "./token.json"
  getter client_id : String
  getter client_secret : String
  property token : Token

  private def initialize
    hash = NamedTuple(client_id: String, client_secret: String).from_json({{read_file("./secrets/secrets.json")}})
    @client_id = hash[:client_id]
    @client_secret = hash[:client_secret]
    @token = Token.load(TOKEN_PATH) || Token.generate(@client_id, @client_secret)
  end

  def self.instance
    @@instance ||= new
  end
end
