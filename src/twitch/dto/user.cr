module Twitch
  record User,
    id : String,
    login : String,
    display_name : String,
    type : String,
    broadcaster_type : String,
    description : String,
    profile_image_url : String,
    offline_image_url : String,
    view_count : Int32,
    created_at : Time do
    include JSON::Serializable
  end
end
