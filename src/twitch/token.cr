require "http/client"
require "json"

record Token,
  access_token : String,
  refresh_token : String,
  expires_at : Time,
  scope : Set(String),
  token_type : String do
  include JSON::Serializable

  # TODO validate token on startup

  def self.load(token_path : String) : Token?
    token = Token.from_json(File.read(token_path)) if File.exists?(token_path)
    token if token && token.scope == Config::SCOPE
  end

  def self.save(token_path : String, token : Token) : Token
    File.write(token_path, token.to_pretty_json)
    token
  end

  def self.generate(token_path : String, scope : Set(String), client_id : String, client_secret : String, force_new_code : Bool = false) : Token
    oauth_url = {{"http://#{read_file("./secrets/.host").id}:#{read_file("./secrets/.port").id}/oauth"}}
    code = generate_code(scope, client_id, oauth_url)

    generate_token(token_path, client_id, client_secret, code, oauth_url)
  end

  def self.refresh(token_path : String, client_id : String, client_secret : String, old_token : Token) : Token
    puts "refreshing token"
    token_url = "https://id.twitch.tv/oauth2/token"
    token_body = {
      "client_id"     => client_id,
      "client_secret" => client_secret,
      "grant_type"    => "refresh_token",
      "refresh_token" => old_token.refresh_token,
    }

    token_resp = HTTP::Client.post(token_url, form: token_body)
    puts "token_resp: #{token_resp.inspect}" unless token_resp.success?

    token_json = NamedTuple(access_token: String, expires_in: Int32, refresh_token: String, scope: Array(String), token_type: String).from_json(token_resp.body)
    save(token_path, Token.new(token_json[:access_token], token_json[:refresh_token], Time.local + Time::Span.new(seconds: token_json[:expires_in]), token_json[:scope].to_set, token_json[:token_type]))
  end

  private def self.generate_code(scope : Set(String), client_id : String, oauth_url : String) : String
    puts "generating a new code"
    code_channel = Channel(String).new
    state = Random.new.hex(20)
    auth_url = "https://id.twitch.tv/oauth2/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{oauth_url}&scope=#{URI.encode_path(scope.join(" "))}&state=#{state}"
    WebServer.start(code_channel) do
      code_resp = HTTP::Client.get(auth_url)
      puts "code_resp: #{code_resp.inspect}" unless code_resp.status.found?
      location = code_resp.headers["Location"]

      puts location
      puts "waiting user to authorize app"
    end

    code_channel.receive
  end

  private def self.generate_token(token_path : String, client_id : String, client_secret : String, code : String, oauth_url : String) : Token
    puts "generating a new token"
    token_url = "https://id.twitch.tv/oauth2/token"
    token_body = {
      "client_id"     => client_id,
      "client_secret" => client_secret,
      "code"          => code,
      "grant_type"    => "authorization_code",
      "redirect_uri"  => oauth_url,
    }

    token_resp = HTTP::Client.post(token_url, form: token_body)
    puts "token_resp: #{token_resp.inspect}" unless token_resp.success?

    token_json = NamedTuple(access_token: String, expires_in: Int32, refresh_token: String, scope: Array(String), token_type: String).from_json(token_resp.body)
    save(token_path, Token.new(token_json[:access_token], token_json[:refresh_token], Time.local + Time::Span.new(seconds: token_json[:expires_in]), token_json[:scope].to_set, token_json[:token_type]))
  end
end
