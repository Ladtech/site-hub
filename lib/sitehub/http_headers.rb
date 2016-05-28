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
    COMMAND_FOLLOWED_BY_SPACES = /,\s+/

    SHOULD_NOT_TRANSFER = [PROXY_CONNECTION].freeze

    HOP_BY_HOP = [CONNECTION_HEADER,
                  KEEP_ALIVE,
                  PROXY_AUTHENTICATE,
                  PROXY_AUTHORIZATION,
                  TE,
                  TRAILERS,
                  TRANSFER_ENCODING,
                  CONTENT_ENCODING].freeze

    def sanitise_headers(src)
      sanitised_headers = remove_excluded_http_headers(with_http_header_names(src))

      modify_location(sanitised_headers) if location_header?(sanitised_headers)
      sanitised_headers
    end

    def extract_http_headers(env)
      headers = without_excluded_headers(env)

      headers = headers.each_with_object(Rack::Utils::HeaderHash.new) do |key_value, hash|
        key, value = key_value
        hash[header_name(key)] = value
      end

      headers.merge!(X_FORWARDED_FOR_HEADER => x_forwarded_for_value(headers, remote_address(env)))
    end

    private

    # sanitise headers
    def remove_excluded_http_headers hash
      connections = split_field(hash[CONNECTION_HEADER])
      hash.reject do |key, _value|
        excluded_header?(key) || connections.member?(key)
      end
    end

    def http_header_name(key)
      key.downcase.gsub(UNDERSCORE, HYPHEN)
    end

    def modify_location headers
      headers[LOCATION_HEADER].gsub!(HTTP_OR_SSL_PORT, EMPTY_STRING)
    end

    def location_header?(sanitised_headers)
      sanitised_headers[LOCATION_HEADER]
    end

    def with_http_header_names hash
      hash.each_with_object({}) do |array, _hash|
        key, value = array
        _hash[http_header_name(key)] = value
      end
    end

    def excluded_header?(key)
      HOP_BY_HOP.member?(key) || SHOULD_NOT_TRANSFER.member?(key)
    end

    def split_field(field)
      field ? field.split(COMMAND_FOLLOWED_BY_SPACES).collect(&:downcase) : []
    end

    # for extract_http_headers
    def forwarded_address_list(headers)
      headers[X_FORWARDED_FOR_HEADER].to_s.split(COMMAND_FOLLOWED_BY_SPACES)
    end

    def header_name(name)
      name.sub(HTTP_PREFIX, EMPTY_STRING).gsub(UNDERSCORE, HYPHEN)
    end

    def remote_address(env)
      env[RackHttpHeaderKeys::REMOTE_ADDRESS_ENV_KEY]
    end

    def without_excluded_headers(env)
      env.reject do |key, value|
        !RackHttpHeaderKeys::HTTP_HEADER_FILTER_EXCEPTIONS.include?(key.to_s.upcase) &&
            (!RACK_HTTP_HEADER_ID.match(key) || value.nil?)
      end
    end

    def x_forwarded_for_value(headers, remote_address)
      (forwarded_address_list(headers) << remote_address).join(COMMA_WITH_SPACE)
    end
  end
end
