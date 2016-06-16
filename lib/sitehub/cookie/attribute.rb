require 'sitehub/string_sanitiser'
require 'sitehub/equality'
class SiteHub
  class Cookie
    class Attribute
      include StringSanitiser, Equality
      attr_reader :name, :value

      def initialize(name, value)
        @name = sanitise(name).to_sym
        @value = sanitise(value)
      end

      def update(value)
        @value = value
      end

      def to_s
        "#{name}=#{value}"
      end
    end
  end
end
