require "kemal"

class WebServer
  def self.start(token_channel : Channel(Token), port : Int32 = {{read_file("./secrets/.port").to_i}}, &block : Channel(String) -> Token )
    Kemal.config.port = port

    code_channel = Channel(String).new
    get "/" do
      "Hello World!"
    end

    get "/oauth" do |env|
      code_channel.send(env.params.query["code"])
      # env
      "Success"
    end

    spawn do
      token = block.call(code_channel)
      Kemal.stop
      token_channel.send(token)
    end
    
    Kemal.run    
  end
end
