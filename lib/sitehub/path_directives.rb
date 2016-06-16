require 'sitehub/path_directive'
class SiteHub
  class PathDirectives < Array
    def initialize(map = {})
      enriched = map.collect do |pattern, path_template|
        matcher = pattern.is_a?(Regexp) ? pattern : /#{pattern}/
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
