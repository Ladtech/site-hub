require 'sitehub/string_sanitiser'
class SiteHub
  class Cookie
    class Attribute
      include StringSanitiser
      attr_accessor :name, :value

      def initialize(name, value)
        @name = sanitise(name).to_s.to_sym
        @value = sanitise(value || EMPTY_STRING)
      end

      def to_s
        "#{name}=#{value}"
      end

      def ==(other)
        other.is_a?(Attribute) && name == other.name && value == other.value
      end
    end
  end
end
