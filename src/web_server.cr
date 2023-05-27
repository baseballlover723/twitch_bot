require "kemal"

class WebServer
  def self.start(port : Int32 = 54258)
    Kemal.config.port = port
    get "/" do
      "Hello World!"
    end
    
    puts "before kemal run"
    spawn do
      puts "in spawn"
    end
    
    Kemal.run    
  end
end
