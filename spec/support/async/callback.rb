module Async
  class Callback
    attr_reader :response

    def call(*args)
      status, headers, body = *args.flatten.to_a
      @response = Rack::Response.new(body, status, headers)
      EventMachine.stop if EventMachine.reactor_running?
    end
  end
end
