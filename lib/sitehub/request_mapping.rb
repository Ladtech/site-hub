require 'sitehub/constants'
require 'sitehub/memoize'
class SiteHub
  class RequestMapping
    extend Memoize

    attr_reader :source_url, :mapped_url, :mapped_path

    BASE_URL_MATCHER = %r{^\w+://[\w+\.-]+(:\d+)?}
    CAPTURE_GROUP_REFERENCE = '$%s'.freeze
    USER_SUPPLIED_CAPTURE = 1..-1

    def initialize(source_url:, mapped_url: EMPTY_STRING, mapped_path:)
      @source_url = source_url
      @mapped_url = mapped_url.to_s.dup
      mapped_path = mapped_path.to_s.dup
      @mapped_path = mapped_path.is_a?(Regexp) ? mapped_path : Regexp.new(mapped_path)
    end

    def computed_uri
      url_components = url_scanner_regex.match(source_url).captures[USER_SUPPLIED_CAPTURE]
      mapped_url.tap do |url|
        url_components.each_with_index do |match, index|
          url.gsub!(CAPTURE_GROUP_REFERENCE % (index + 1), match)
        end
      end
      URI(mapped_url)
    end
    memoize :computed_uri

    def host
      URI(source_url).host
    end
    memoize :host

    private

    def url_scanner_regex
      /#{BASE_URL_MATCHER.source}#{mapped_path.source}/
    end
  end
end
