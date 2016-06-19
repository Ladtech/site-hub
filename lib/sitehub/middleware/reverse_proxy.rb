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
        status, headers, body = @app.call(env).to_a
        mapping = env[REQUEST].mapping

        headers[LOCATION_HEADER] = location(headers, mapping) if headers[LOCATION_HEADER]

        rewrite_cookies(headers, substitute_domain: mapping.host) if headers[SET_COOKIE]

        [status, HttpHeaders.new(headers), body]
      end

      def location(headers, mapping)
        location_header = headers[LOCATION_HEADER]
        path_directives.find(location_header).apply(location_header, mapping.source_url)
      end
    end
  end
end
