require "kemal"

class WebServer
  def self.start(code_channel : Channel(String), port : Int32 = {{read_file("./secrets/.port").to_i}}, &block)
    Kemal.config.port = port

    get "/" do
      "Hello World!"
    end

    get "/oauth" do |env|
      spawn do
        Kemal.stop
        code_channel.send(env.params.query["code"])
      end
      "Success"
    end

    spawn &block
    
    Kemal.run    
  end
end
