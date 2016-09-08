require_relative '../collection'
require_relative 'split_route_collection/split'
class SiteHub
  class Collection < Hash
    class SplitRouteCollection < Collection
      class InvalidSplitException < StandardError
      end

      FIXNUM_ERR_MSG = 'splits must be a Fixnum'.freeze
      SPLIT_ERR_MSG = 'total split percentages can not be greater than 100%'.freeze
      INVALID_SPILTS_MSG = 'splits do not add up to 100% and no default has been specified'.freeze
      MAX = 100
      MIN = 0

      def add(id, value, percentage)
        raise InvalidSplitException, FIXNUM_ERR_MSG unless percentage.is_a?(Fixnum)
        upper_bound = lower_bound + percentage

        raise InvalidSplitException, SPLIT_ERR_MSG if upper_bound > MAX
        self[id] = Split.new(lower_bound, upper_bound, value)
      end

      def resolve(*args)
        random = rand(MAX)
        result = _values.find { |split| random >= split.lower && random < split.upper }
        result ? result.value.resolve(*args) : nil
      end

      def transform(&block)
        _values.each { |split| split.update_value(&block) }
      end

      def [](key)
        key?(key) ? super(key).value : super(key)
      end

      alias _values values

      def values
        super().collect(&:value)
      end

      def valid?
        last = _values.last
        return true if last && last.upper == MAX

        warn(INVALID_SPILTS_MSG)
        false
      end

      private

      def lower_bound
        _values.empty? ? MIN : _values.last.upper
      end
    end
  end
end
