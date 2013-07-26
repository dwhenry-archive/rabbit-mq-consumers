require 'rack'
module HttpServer
  def start(response_body)
    Thread.abort_on_exception=true
    @thread = Thread.start do
      app(response_body).start
    end
  end

  def stop
    # @app && @app.server.stop
  end

  def app(response_body)
    @app ||= Rack::Server.new(
      builder: "run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['#{response_body}']] }",
      AccessLog: []
    )
  end

  extend self
end
