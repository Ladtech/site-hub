class SiteHub
  class PathDirective
    attr_reader :matcher, :path_template

    def initialize matcher, path_template
      @matcher, @path_template = matcher, path_template
    end

    def match? url
      !!matcher.match(url)
    end

    def path_template
      @path_template.dup
    end

    def apply url
      url_components = matcher.match(url).captures

      path_template.tap do |p|
        url_components.each_with_index do |m, index|
          p.gsub!(RequestMapping::CAPTURE_GROUP_REFERENCE % (index+1), m)
        end
      end

    end

    def == other
      other.is_a?(PathDirective) && self.matcher == other.matcher && self.path_template == other.path_template
    end
  end
end