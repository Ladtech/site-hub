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
          location = transform_location(location_header, mapping.source_url)
          downstream_headers[LOCATION_HEADER] = location if location
        end
      end

      def transform_location(old_location, source_url)
        path_directives.find(old_location).apply(old_location, source_url)
      end
    end
  end
end
