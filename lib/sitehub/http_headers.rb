require 'sitehub/constants'

class SiteHub
  # module HttpHeaders - provides methods for translating HTTP headers names to and
  # from RACK to HTTP compliant names.
  module HttpHeaders
    include Constants, Constants::HttpHeaderKeys

    HTTP_PREFIX = /^HTTP_/
    RACK_HTTP_HEADER_ID = /#{HTTP_PREFIX.source}[A-Z_]+$/

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

    #  Call with headers extraced from rack (http-compliant header names)
    def filter_http_headers(env)
      remove_headers(env, hop_by_hop_headers(env).concat(EXCLUDED_HEADERS))
    end

    def extract_http_headers_from_rack_env(env)
      without_excluded_headers(env).each_with_object({}) do |key_value, hash|
        hash[header_name(key_value[0])] = key_value[1]
      end
    end

    private

    def hop_by_hop_headers(env)
      field = env[CONNECTION_HEADER] || EMPTY_STRING
      field.split(COMMA).collect(&:downcase)
    end

    def remove_headers(headers, excluded)
      headers.reject do |key, _value|
        excluded.member?(key)
      end
    end

    def header_name(name)
      name.sub(HTTP_PREFIX, EMPTY_STRING).downcase.gsub(UNDERSCORE, HYPHEN)
    end

    def without_excluded_headers(env)
      env.reject do |key, value|
        !RackHttpHeaderKeys::HTTP_HEADER_FILTER_EXCEPTIONS.include?(key.to_s.upcase) &&
          (!RACK_HTTP_HEADER_ID.match(key) || value.nil?)
      end
    end
  end
end
