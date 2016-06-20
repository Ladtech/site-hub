require 'sitehub/equality'
class SiteHub
  class LocationRewriter
    include Equality

    attr_reader :matcher, :path_template

    def initialize(matcher, path_template)
      @matcher = matcher
      @path_template = path_template
    end

    def match?(url)
      matcher.match(url).is_a?(MatchData)
    end

    def apply(downstream_url, source_url)
      url_components = matcher.match(downstream_url).captures

      path = path_template.dup.tap do |template|
        url_components.each.with_index(1) do |component, index|
          template.gsub!(RequestMapping::CAPTURE_GROUP_REFERENCE % index, component)
        end
      end

      "#{source_url[RequestMapping::BASE_URL_MATCHER]}#{path}"
    end
  end
end
