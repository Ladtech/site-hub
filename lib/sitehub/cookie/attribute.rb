require 'sitehub/string_utils'
require 'sitehub/equality'
class SiteHub
  class Cookie
    class Attribute
      include Equality
      attr_reader :name, :value

      def initialize(name, value)
        @name = StringUtils.sanitise(name).to_sym
        @value = StringUtils.sanitise(value)
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
