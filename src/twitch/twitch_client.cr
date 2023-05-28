require "http/client"
require "./config"

class TwitchClient
  def initialize
    validate
  end

  def validate : Bool
    puts "validating token"
    validate_url = "https://id.twitch.tv/oauth2/validate"

    validate_resp = HTTP::Client.get(validate_url, headers: HTTP::Headers{"Authorization" => "OAuth #{Config.instance.token.access_token}"})
    puts "validate_resp: #{validate_resp.inspect}" unless validate_resp.success?
    validate_resp.success?
  end
end
