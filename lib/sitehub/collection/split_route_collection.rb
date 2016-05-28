require_relative '../collection'
require_relative 'split_route_collection/split'
class SiteHub
  class Collection < Hash
    class SplitRouteCollection < Collection
      class InvalidSplitException < Exception
      end

      FIXNUM_ERR_MSG = 'splits must be a Fixnum'.freeze
      SPLIT_ERR_MSG = 'total split percentages can not be greater than 100%'.freeze

      def initialize(hash = {})
        hash.each do |value, percentage|
          add(value.id, value, percentage)
        end
      end

      def add(id, value, percentage)
        raise InvalidSplitException, FIXNUM_ERR_MSG unless percentage.is_a?(Fixnum)
        lower = values.last ? values.last.upper : 0
        upper = lower + percentage

        raise InvalidSplitException, SPLIT_ERR_MSG if upper > 100
        self[id] = Split.new(lower, upper, value)
      end

      def resolve(*args)
        random = rand(100)
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
        return true if last && last.upper == 100

        warn('splits do not add up to 100% and no default has been specified')
        false
      end
    end
  end
end
