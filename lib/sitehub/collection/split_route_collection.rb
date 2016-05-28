require_relative '../collection'
require_relative 'split_route_collection/split'
class SiteHub
  class Collection < Hash
    class SplitRouteCollection < Collection
      class InvalidSplitException < Exception
      end

      FIXNUM_ERR_MSG = 'splits must be a Fixnum'.freeze
      SPLIT_ERR_MSG = 'total split percentages can not be greater than 100%'.freeze
      INVALID_SPILTS_MSG = 'splits do not add up to 100% and no default has been specified'.freeze
      MAX = 100
      MIN = 0

      def initialize(hash = {})
        hash.each do |value, percentage|
          add(value.id, value, percentage)
        end
      end

      def add(id, value, percentage)
        raise InvalidSplitException, FIXNUM_ERR_MSG unless percentage.is_a?(Fixnum)
        lower = values.last ? values.last.upper : MIN
        upper = lower + percentage

        raise InvalidSplitException, SPLIT_ERR_MSG if upper > MAX
        self[id] = Split.new(lower, upper, value)
      end

      def resolve(*args)
        random = rand(MAX)
        result = values.find { |split| random >= split.lower && random < split.upper }
        result ? result.value.resolve(*args) : nil
      end

      def transform
        values.each do |split|
          split.value = yield(split.value)
        end
      end

      def [](key)
        result = super(key)
        result && result.value
      end

      def valid?
        last = values.last
        return true if last && last.upper == MAX

        warn(INVALID_SPILTS_MSG)
        false
      end
    end
  end
end
