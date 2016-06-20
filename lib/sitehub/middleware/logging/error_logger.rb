require 'logger'
require 'sitehub/constants'
require_relative 'log_wrapper'
require_relative 'log_stash'
class SiteHub
  module Middleware
    module Logging
      class ErrorLogger
        include Constants
        LOG_TEMPLATE = '[%s] ERROR: %s - %s'.freeze

        attr_reader :logger

        def initialize(app, logger = Logger.new(STDERR))
          @app = app
          @logger = LogWrapper.new(logger)
        end

        def call(env)
          errors = env[ERRORS] ||= LogStash.new
          @app.call(env).tap do
            unless errors.empty?
              messages = errors.collect do |log_entry|
                log_message(error: log_entry.message, transaction_id: env[RackHttpHeaderKeys::TRANSACTION_ID])
              end

              logger.write(messages.join(NEW_LINE))
            end
          end
        end

        def log_message(error:, transaction_id:)
          format(LOG_TEMPLATE, Time.now.strftime(TIME_STAMP_FORMAT), transaction_id, error)
        end
      end
    end
  end
end
