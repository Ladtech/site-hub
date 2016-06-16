require 'logger'
require 'rack/commonlogger'
require_relative 'log_wrapper'
require 'sitehub/constants'
require 'sitehub/middleware/logging/request_log'

# Very heavily based on Rack::CommonLogger
class SiteHub
  class Response < Rack::Response
    attr_reader :status, :headers, :body, :time
    def initialize(body, status, headers)
      super
      @time = Time.now
    end
    alias headers header
  end

  module Middleware
    module Logging
      class AccessLogger
        attr_reader :logger, :start_time

        include Constants

        FORMAT = %(%s - %s [%s] transaction_id:%s: "%s %s%s => %s %s" %d %s %0.4f\n).freeze
        ZERO_STRING = '0'.freeze
        STATUS_RANGE = 0..3

        def initialize(app, logger = ::Logger.new(STDOUT))
          @app = app
          @logger = LogWrapper.new(logger)
        end

        def call(env)
          env[REQUEST] = Request.new(env: env)
          @app.call(env).tap do |response|
            status, headers, body = response.to_a
            response = Response.new(body, status, headers)
            logger.write(RequestLog.new(env[REQUEST], response).to_s)
          end
        end
      end
    end
  end
end
