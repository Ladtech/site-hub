require 'sitehub/constants'
class SiteHub
  class RequestMapping
    attr_reader :source_url, :mapped_url, :mapped_path

    BASE_URL_MATCHER = %r{^\w+://[\w+\.-]+(:\d+)?}
    CAPTURE_GROUP_REFERENCE = '$%s'.freeze
    USER_SUPPLIED_CAPTURE = 1..-1

    def initialize(source_url:, downstream_url: EMPTY_STRING, mapped_url: EMPTY_STRING, mapped_path:)
      @source_url = source_url
      @mapped_url = mapped_url.dup
      @mapped_path = mapped_path.is_a?(Regexp) ? mapped_path : Regexp.new(mapped_path)
      @downstream_url = downstream_url
    end

    def cookie_path
      mapped_path.source[/^(.*)?\(/, 1].gsub(%r{/$}, '') if mapped_path.is_a?(Regexp)
    end

    def computed_uri
      @computed_uri ||= begin
        url_components = url_scanner_regex.match(source_url).captures[USER_SUPPLIED_CAPTURE]
        mapped_url.tap do |url|
          url_components.each_with_index do |match, index|
            url.gsub!(CAPTURE_GROUP_REFERENCE % (index + 1), match)
          end
        end
        URI(mapped_url)
      end
    end

    def ==(other)
      other.is_a?(RequestMapping) &&
        source_url == other.source_url &&
        mapped_url == other.mapped_url &&
        mapped_path == other.mapped_path
    end

    private

    def url_scanner_regex
      /#{BASE_URL_MATCHER.source}#{mapped_path.source}/
    end
  end
end
