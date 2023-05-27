record Token, 
access_token : String, 
refresh_token : String, 
expires_at : Time,
scope : Array(String),
token_type : String do
  def self.load(token_path : String) : Token?
    return nil unless File.exists?(token_path)
  end

  def self.generate(client_id : String, client_secret : String) : Token
    #TODO generate token

    Token.new("access_token", "refresh_token", Time.local, ["scope"], "token_type")
  end
end
