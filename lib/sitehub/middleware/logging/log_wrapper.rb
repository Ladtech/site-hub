require 'sitehub/equality'
class SiteHub
  module Middleware
    module Logging
      class LogWrapper
        include Equality

        attr_reader :logger

        def initialize(logger)
          @logger = logger
        end

        def write(msg)
          if logger.respond_to?(:<<)
            logger << msg
          elsif logger.respond_to?(:write)
            logger.write(msg)
          end
        end
      end
    end
  end
end
