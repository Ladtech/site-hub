class SiteHub
  class PathDirective
    attr_reader :matcher, :path_template

    def initialize(matcher, path_template)
      @matcher = matcher
      @path_template = path_template
    end

    def match?(url)
      !matcher.match(url).nil?
    end

    def path_template
      @path_template.dup
    end

    def apply(url)
      url_components = matcher.match(url).captures

      path_template.tap do |template|
        url_components.each.with_index(1) do |component, index|
          template.gsub!(RequestMapping::CAPTURE_GROUP_REFERENCE % index, component)
        end
      end
    end

    def ==(other)
      other.is_a?(PathDirective) && matcher == other.matcher && path_template == other.path_template
    end
  end
end
