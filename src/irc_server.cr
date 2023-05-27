class IRC_Server
  getter output_channel : Channel(String)
  def initialize(@output_channel : Channel(String))
  end
end
