class SiteHub
  class Collection
    class SplitRouteCollection < Collection
      class Split
        attr_reader :upper, :lower, :value

        def initialize(lower, upper, value)
          @upper = upper
          @lower = lower
          @value = value
        end

        def update_value
          @value = yield(@value)
        end

        # TODO: write equality method mixin
        def ==(other)
          other.is_a?(Split) && other.lower == lower && other.upper == upper
        end
      end
    end
  end
end
