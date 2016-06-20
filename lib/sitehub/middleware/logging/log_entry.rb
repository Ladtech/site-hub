require 'sitehub/equality'
class SiteHub
  module Middleware
    module Logging
      class LogEntry
        include Equality
        attr_reader :message, :time

        def initialize(message, time = Time.now)
          @message = message
          @time = time
        end
      end
    end
  end
end
