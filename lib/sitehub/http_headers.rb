require 'sitehub/constants'

class SiteHub
  # module HttpHeaders - provides methods for translating HTTP headers names to and
  # from RACK to HTTP compliant names.
  module HttpHeaders
    include Constants::HttpHeaderKeys
    include Constants

    HTTP_OR_SSL_PORT = /:80(?!\d+)|:443/
    HTTP_PREFIX = /^HTTP_/
    RACK_HTTP_HEADER_ID = /#{HTTP_PREFIX.source}[A-Z_]+$/
    COMMA = ','.freeze

    SHOULD_NOT_TRANSFER = [PROXY_CONNECTION].freeze

    EXCLUDED_HEADERS = [CONNECTION_HEADER,
                        KEEP_ALIVE,
                        PROXY_AUTHENTICATE,
                        PROXY_AUTHORIZATION,
                        TE,
                        TRAILERS,
                        TRANSFER_ENCODING,
                        CONTENT_ENCODING,
                        UPGRADE].freeze

    #  Call with headers extraced from rack (http-compliant header names)
    def http_headers(env)
      # remove hop by hop headers identified in connection header
      headers = env.each_with_object({}) do |key_value, hash|
        key, value = *key_value
        hash[key.downcase] = value
      end
      headers = without_hop_by_hop_headers(headers)

      # remove excluded headers
      remove_excluded_http_headers headers
    end

    def remove_excluded_http_headers(env)
      env.reject do |key, _value|
        excluded_header?(key.downcase)
      end
    end

    def without_hop_by_hop_headers(env)
      hop_by_hop_headers = split_field(env[CONNECTION_HEADER])
      env.reject do |key, _value|
        hop_by_hop_headers.member?(key)
      end
    end

    def extract_http_headers_from_rack_env(env)
      headers = without_excluded_headers(env)

      headers.each_with_object(Rack::Utils::HeaderHash.new) do |key_value, hash|
        key, value = key_value
        hash[header_name(key)] = value
      end
    end

    private

    def excluded_header?(key)
      EXCLUDED_HEADERS.member?(key) || SHOULD_NOT_TRANSFER.member?(key)
    end

    def split_field(field)
      field ? field.split(COMMA).collect(&:downcase) : []
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
