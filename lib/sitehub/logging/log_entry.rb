class SiteHub
  module Logging
    class LogEntry
      attr_reader :message, :time
      def initialize message, time=Time.now
        @message, @time = message, time
      end

      def == other
        other.is_a?(LogEntry) && self.message == other.message && self.time == other.time
      end
    end
  end
end