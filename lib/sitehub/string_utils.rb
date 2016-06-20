class SiteHub
  module StringUtils
    class << self
      def split(header_value)
        header_value.to_s.split(COMMA)
      end

      def sanitise(string)
        string.to_s.chomp.strip
      end
    end
  end
end
