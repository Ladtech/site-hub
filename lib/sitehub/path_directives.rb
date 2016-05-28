require 'sitehub/path_directive'
class SiteHub
  class PathDirectives < Array
    def initialize(map = {})
      enriched = map.map do |array|
        matcher = array.first
        path_template = array.last

        matcher = matcher.is_a?(Regexp) ? matcher : /#{matcher}/
        PathDirective.new(matcher, path_template)
      end

      super enriched
    end

    def find(url)
      super() do |directive|
        directive.match?(url)
      end
    end
  end
end
