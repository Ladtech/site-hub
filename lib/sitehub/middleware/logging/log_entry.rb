class SiteHub
  module Middleware
    module Logging
      class LogEntry
        attr_reader :message, :time

        def initialize(message, time = Time.now)
          @message = message
          @time = time
        end

        def ==(other)
          other.is_a?(LogEntry) && message == other.message && time == other.time
        end
      end
    end
  end
end
