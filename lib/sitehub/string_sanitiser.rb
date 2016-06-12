class SiteHub
  module StringSanitiser
    def sanitise(string)
      string.chomp.strip
    end

    def split(header_value)
      header_value.to_s.split(COMMA)
    end
  end
end
