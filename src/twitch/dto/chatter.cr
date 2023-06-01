module Twitch
  record Chatter,
    user_id : String,
    user_name : String do
    include JSON::Serializable
  end
end
