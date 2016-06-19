require 'sitehub/path_directive'
require 'sitehub/nil_path_directive'
class SiteHub
  class PathDirectives < Array
    DEFAULT = NilPathDirective.new

    def initialize(map = {})
      enriched = map.collect do |pattern, path_template|
        matcher = pattern.is_a?(Regexp) ? pattern : /#{pattern}/
        PathDirective.new(matcher, path_template)
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
