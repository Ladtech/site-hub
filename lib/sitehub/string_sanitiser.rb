class SiteHub
  module StringSanitiser
    def sanitise(string)
      string.chomp.strip
    end
  end
end