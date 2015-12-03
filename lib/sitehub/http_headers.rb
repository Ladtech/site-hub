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
      f ? f.split(COMMAND_FOLLOWED_BY_SPACES).collect { |i| i.downcase } : []
    end

    def sanitise_headers(src)

      sanitised_headers = {}

      connections = split_field(src[CONNECTION_HEADER])
      src.each do |key, value|
        key = key.downcase.gsub(UNDERSCORE, HYPHEN)
        if HopByHop.member?(key) ||
            connections.member?(key) ||
            ShouldNotTransfer.member?(key)
          next
        end
        sanitised_headers[key] = value
      end

      sanitised_headers[LOCATION_HEADER].gsub!(HTTP_OR_SSL_PORT, EMPTY_STRING) if sanitised_headers[LOCATION_HEADER]

      sanitised_headers
    end



    def extract_http_headers(env)
      headers = env.reject do |k, v|
        !RackHttpHeaderKeys::HTTP_HEADER_FILTER_EXCEPTIONS.include?(k.to_s.upcase) && (!(RACK_HTTP_HEADER_ID === k) || v.nil?)
      end.map do |k, v|
        [reconstruct_header_name(k), v]
      end.inject(Rack::Utils::HeaderHash.new) do |hash, k_v|
        k, v = k_v
        hash[k] = v
        hash
      end

      x_forwarded_for = (headers[X_FORWARDED_FOR_HEADER].to_s.split(COMMAND_FOLLOWED_BY_SPACES) << env[RackHttpHeaderKeys::REMOTE_ADDRESS_ENV_KEY]).join(COMMA_WITH_SPACE)

      headers.merge!(X_FORWARDED_FOR_HEADER => x_forwarded_for)
    end



    def reconstruct_header_name(name)
      name.sub(HTTP_PREFIX, EMPTY_STRING).gsub(UNDERSCORE, HYPHEN)
    end
  end
end