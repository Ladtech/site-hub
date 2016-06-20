class SiteHub
  module Middleware
    class ErrorHandling
      ERROR_RESPONSE = Rack::Response.new(['error'], 500, {})

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call env
      rescue StandardError => exception
        env[ERRORS] << exception.message
        ERROR_RESPONSE.dup
      end
    end
  end
end
