require 'sitehub/string_sanitiser'
class SiteHub
  class Cookie
    class Flag
      include StringSanitiser
      attr_accessor :name

      def initialize(flag)
        @name = sanitise(flag).to_sym
      end

      def to_s
        name.to_s
      end

      def ==(other)
        other.is_a?(Flag) && name == other.name
      end
    end
  end
end
