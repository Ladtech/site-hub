class SiteHub


  class HttpHeadersObject < Hash
    HTTP_PREFIX = /^HTTP_/
    RACK_HTTP_HEADER_ID = /#{HTTP_PREFIX.source}[A-Z_]+$/

    class << self
      def from_rack_env env
        new(format_keys(remove_rack_specific_headers(env)))
      end

      private
      def remove_rack_specific_headers env
        env.reject do |key, value|
          !Constants::RackHttpHeaderKeys::HTTP_HEADER_FILTER_EXCEPTIONS.include?(key.to_s.upcase) &&
              (!RACK_HTTP_HEADER_ID.match(key) || value.nil?)
        end
      end

      def format_keys env
        env.each_with_object({}) do |key_value, hash|
          hash[header_name(key_value[0])] = key_value[1]
        end
      end

      def header_name(name)
        name.sub(HTTP_PREFIX, EMPTY_STRING).downcase.gsub(UNDERSCORE, HYPHEN)
      end

    end

    include Constants, Constants::HttpHeaderKeys

    EXCLUDED_HEADERS = [CONNECTION_HEADER,
                        KEEP_ALIVE,
                        PROXY_CONNECTION,
                        PROXY_AUTHENTICATE,
                        PROXY_AUTHORIZATION,
                        TE,
                        TRAILERS,
                        TRANSFER_ENCODING,
                        CONTENT_ENCODING,
                        UPGRADE].freeze

    def initialize env
      env.each do |key, value|
        self[key] = value
      end

      filter_prohibited_headers
    end



    private
    def filter_prohibited_headers
      remove_headers(hop_by_hop_headers.concat(EXCLUDED_HEADERS))
    end

    def hop_by_hop_headers
      field = self[CONNECTION_HEADER] || EMPTY_STRING
      field.split(COMMA).collect(&:downcase)
    end

    def remove_headers(excluded)
      reject! do |key, _value|
        excluded.member?(key)
      end
    end

  end
end