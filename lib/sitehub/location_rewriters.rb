require 'sitehub/location_rewriter'
require 'sitehub/nil_location_rewriter'
class SiteHub
  class LocationRewriters < Array
    DEFAULT = NilLocationRewriter.new

    def initialize(map = {})
      enriched = map.collect do |pattern, path_template|
        matcher = pattern.is_a?(Regexp) ? pattern : /#{pattern}/
        LocationRewriter.new(matcher, path_template)
      end

      super enriched
    end

    def find(url)
      result = super() do |directive|
        directive.match?(url)
      end
      result || DEFAULT
    end
  end
end
