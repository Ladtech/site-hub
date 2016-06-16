require_relative 'callback'
module Async
  class Middleware
    def initialize(app)
      @app = app
    end

    def last_response
      callback.response
    end

    def callback
      @callback ||= Callback.new
    end

    def call(env)
      env['async.callback'] = callback

      catch(:async) do
        @app.call env
      end

      [200, {}, []]
    end
  end
end
