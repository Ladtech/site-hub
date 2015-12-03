require 'sitehub/cookie_rewriting'
require 'sitehub/path_directives'
require 'sitehub/request_mapping'
require 'sitehub/constants'

class SiteHub
  class ReverseProxy
    include HttpHeaders, CookieRewriting

    attr_reader :path_directives

    def initialize app, directives
      @app = app
      @path_directives = PathDirectives.new(directives)
    end



    def call env
      downstream_response = @app.call(env)

      request_mapping = env[REQUEST_MAPPING]

      begin
        downstream_status, downstream_headers, downstream_body = downstream_response.to_a

        if downstream_headers[HttpHeaders::LOCATION_HEADER]
          downstream_uri = URI(downstream_headers[HttpHeaders::LOCATION_HEADER])
          mapped_downstream_uri = URI(request_mapping.mapped_url)
          if downstream_uri.host == mapped_downstream_uri.host && downstream_uri.port == mapped_downstream_uri.port
            downstream_headers[HttpHeaders::LOCATION_HEADER] = interpolate_location(downstream_headers[HttpHeaders::LOCATION_HEADER], request_mapping.source_url)
          end
        end

        rewrite_cookies(downstream_headers, substitute_domain: URI(request_mapping.source_url).host) if downstream_headers[HttpHeaders::SET_COOKIE]

        Rack::Response.new(downstream_body, downstream_status, downstream_headers)
      end

    end

    def interpolate_location(old_location, source_url)
      path = if path_directives.empty?
               URI(old_location).path
             else
               path_directives.find(old_location).apply(old_location)
             end

      base_url = source_url[RequestMapping::BASE_URL_MATCHER]
      "#{base_url}#{path}"
    end
  end
end
