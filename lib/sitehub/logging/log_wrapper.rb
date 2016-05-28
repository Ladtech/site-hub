class SiteHub
  module Logging
    class LogWrapper
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

      def ==(other)
        other.is_a?(LogWrapper) && logger == other.logger
      end
    end
  end
end
