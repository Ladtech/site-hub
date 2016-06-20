require 'sitehub/string_utils'
require 'sitehub/equality'
class SiteHub
  class Cookie
    class Flag
      include Equality
      attr_reader :name

      def initialize(flag)
        @name = StringUtils.sanitise(flag).to_sym
      end

      def to_s
        name.to_s
      end
    end
  end
end
