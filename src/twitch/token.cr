require "http/client"

record Token,
  access_token : String,
  refresh_token : String,
  expires_at : Time,
  scope : Array(String),
  token_type : String do
  def self.load(token_path : String) : Token?
    # TODO load token
    return nil unless File.exists?(token_path)
  end

  def self.generate(client_id : String, client_secret : String) : Token
    code_channel = Channel(String).new
    oauth_url = "http://#{{{read_file("./secrets/.host")}}}:#{{{read_file("./secrets/.port")}}}/oauth"
    scope = "channel%3Amanage%3Apolls+channel%3Aread%3Apolls"
    state = Random.new.hex(20)
    auth_url = "https://id.twitch.tv/oauth2/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{oauth_url}&scope=#{scope}&state=#{state}"
    WebServer.start(code_channel) do
      resp = HTTP::Client.get(auth_url)
      location = resp.headers["Location"]

      puts location
      puts "waiting user to authorize app"
    end

    code = code_channel.receive
    token_url = "https://id.twitch.tv/oauth2/token"
    token_body = {
      "client_id"     => client_id,
      "client_secret" => client_secret,
      "code"          => code,
      "grant_type"    => "authorization_code",
      "redirect_uri"  => oauth_url,
    }
  
    token_resp = HTTP::Client.post(token_url, form: token_body)
    token_json = NamedTuple(access_token: String, expires_in: Int32, refresh_token: String, scope: Array(String), token_type: String).from_json(token_resp.body)
    token = Token.new(token_json[:access_token], token_json[:refresh_token], Time.local + Time::Span.new(seconds: token_json[:expires_in]), token_json[:scope], token_json[:token_type])

    # TODO save token
    token
  end
end
