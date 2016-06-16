require 'sitehub/string_sanitiser'
require 'sitehub/equality'
class SiteHub
  class Cookie
    class Flag
      include StringSanitiser, Equality
      attr_accessor :name

      def initialize(flag)
        @name = sanitise(flag).to_sym
      end

      def to_s
        name.to_s
      end
    end
  end
end
