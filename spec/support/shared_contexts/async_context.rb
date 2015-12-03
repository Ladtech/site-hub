shared_context :async do
  class Callback
    attr_reader :response

    def call *args
      status, headers, body = *args.flatten.to_a
      @response = Rack::Response.new(body, status, headers)
      EventMachine.stop if EventMachine.reactor_running?
    end
  end

  def callback
    @callback ||= Callback.new
  end

  def async_response_handler
    @async_response_handler ||= begin
      instance_double(EM::DefaultDeferrable).tap do |handler|
        allow(handler).to receive(:succeed) do |arg|
          sitehub_response = arg[:downstream_response]
          handler.instance_variable_set(:@arg, arg)
          sitehub_response = sitehub_response.to_a
          handler.instance_variable_set(:@last_response, Rack::Response.new(sitehub_response[2], sitehub_response[0], sitehub_response[1]))
          EM.stop
        end

        def handler.last_response
          @last_response
        end

        def handler.callback_args
          @arg
        end
      end
    end
  end

  def last_response
    app.last_response
  end

  def async_middleware
    Class.new do
      def initialize app
        @app = app
      end

      def last_response
        callback.response
      end

      def callback
        @callback ||= Callback.new
      end


      def call env

        env['async.callback'] = callback

        catch(:async) do
          @app.call env
        end

        [200, {}, []]
      end
    end
  end
end
