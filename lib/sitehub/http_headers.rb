require 'sitehub/constants'
class SiteHub
  module HttpHeaders
    include Constants::HttpHeaderKeys
    include Constants

    HTTP_OR_SSL_PORT = /:80(?!\d+)|:443/
    HTTP_PREFIX = /^HTTP_/
    RACK_HTTP_HEADER_ID = /#{HTTP_PREFIX.source}[A-Z_]+$/
    COMMAND_FOLLOWED_BY_SPACES = /,\s+/

    def split_field(f)
      f ? f.split(COMMAND_FOLLOWED_BY_SPACES).collect(&:downcase) : []
    end

    def sanitise_headers(src)
      connections = split_field(src[CONNECTION_HEADER])

      {}.tap do |sanitised_headers|
        src.each do |key, value|
          key = key.downcase.gsub(UNDERSCORE, HYPHEN)
          next if HopByHop.member?(key) || connections.member?(key) || ShouldNotTransfer.member?(key)
          sanitised_headers[key] = value
        end

        sanitised_headers[LOCATION_HEADER].gsub!(HTTP_OR_SSL_PORT, EMPTY_STRING) if sanitised_headers[LOCATION_HEADER]
      end
    end

    def extract_http_headers(env)
      headers = remove_excluded_headers(env)

      headers = headers.to_a.each_with_object(Rack::Utils::HeaderHash.new) do |k_v, hash|
        k, v = k_v
        hash[reconstruct_header_name(k)] = v
        hash
      end

      remote_address = env[RackHttpHeaderKeys::REMOTE_ADDRESS_ENV_KEY]
      headers.merge!(X_FORWARDED_FOR_HEADER => x_forwarded_for_value(headers, remote_address))
    end

    def x_forwarded_for_value(headers, remote_address)
      (forwarded_address_list(headers) << remote_address).join(COMMA_WITH_SPACE)
    end

    def forwarded_address_list(headers)
      headers[X_FORWARDED_FOR_HEADER].to_s.split(COMMAND_FOLLOWED_BY_SPACES)
    end

    def remove_excluded_headers(env)
      env.reject do |k, v|
        !RackHttpHeaderKeys::HTTP_HEADER_FILTER_EXCEPTIONS.include?(k.to_s.upcase) &&
          (!RACK_HTTP_HEADER_ID.match(k) || v.nil?)
      end
    end

    def reconstruct_header_name(name)
      name.sub(HTTP_PREFIX, EMPTY_STRING).gsub(UNDERSCORE, HYPHEN)
    end
  end
end
