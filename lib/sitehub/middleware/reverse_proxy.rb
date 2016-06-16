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
        downstream_status, downstream_headers, downstream_body = @app.call(env).to_a
        request_mapping = env[REQUEST].mapping

        transform_headers(downstream_headers, request_mapping)

        rewrite_cookies(downstream_headers, substitute_domain: request_mapping.host) if downstream_headers[SET_COOKIE]

        [downstream_status, HttpHeaders.new(downstream_headers), downstream_body]
      end

      def transform_headers(downstream_headers, mapping)
        location_header = downstream_headers[LOCATION_HEADER]
        if location_header
          downstream_uri = URI(location_header)
          mapped_downstream_uri = URI(mapping.mapped_url)
          if downstream_uri.host == mapped_downstream_uri.host && downstream_uri.port == mapped_downstream_uri.port
            location = interpolate_location(location_header, mapping.source_url)
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
