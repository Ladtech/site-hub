require 'sitehub/equality'
class SiteHub
  class Collection
    class SplitRouteCollection < Collection
      class Split
        attr_reader :upper, :lower, :value

        include Equality

        def initialize(lower, upper, value)
          @upper = upper
          @lower = lower
          @value = value
        end

        def update_value
          @value = yield(@value)
        end
      end
    end
  end
end
