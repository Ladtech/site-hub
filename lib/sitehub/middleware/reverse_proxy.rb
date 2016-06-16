require 'sitehub/cookie_rewriting'
require 'sitehub/path_directives'
require 'sitehub/request_mapping'
require 'sitehub/constants'

class SiteHub
  module Middleware
    class ReverseProxy
      include CookieRewriting, Constants::HttpHeaderKeys

      attr_reader :path_directives

      def initialize(app, directives)
        @app = app
        @path_directives = PathDirectives.new(directives)
      end

      def call(env)
        downstream_response = @app.call(env)

        request_mapping = env[REQUEST].mapping

        downstream_status, downstream_headers, downstream_body = downstream_response.to_a

        transform_headers(downstream_headers, request_mapping)

        if downstream_headers[SET_COOKIE]
          rewrite_cookies(downstream_headers, substitute_domain: request_mapping.host)
        end

        Rack::Response.new(downstream_body, downstream_status, HttpHeadersObject.new(downstream_headers))
      end

      def transform_headers(downstream_headers, mapping)
        if downstream_headers[LOCATION_HEADER]
          downstream_uri = URI(downstream_headers[LOCATION_HEADER])
          mapped_downstream_uri = URI(mapping.mapped_url)
          if downstream_uri.host == mapped_downstream_uri.host && downstream_uri.port == mapped_downstream_uri.port
            location = interpolate_location(downstream_headers[LOCATION_HEADER], mapping.source_url)
            downstream_headers[LOCATION_HEADER] = location
          end
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
end
