require_relative 'log_entry'
class SiteHub
  module Logging
    class LogStash < Array
      def <<(message)
        super(LogEntry.new(message))
      end
    end
  end
end
