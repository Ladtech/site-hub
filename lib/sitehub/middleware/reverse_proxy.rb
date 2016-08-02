require 'sitehub/cookie/rewriting'
require 'sitehub/location_rewriters'
require 'sitehub/request_mapping'
require 'sitehub/constants'

class SiteHub
  module Middleware
    class ReverseProxy
      include Cookie::Rewriting, Constants::HttpHeaderKeys, Equality

      attr_reader :path_directives

      def initialize(app, directives)
        @app = app
        @path_directives = LocationRewriters.new(directives)
      end

      def call(env)
        status, headers, body = @app.call(env).to_a
        mapping = env[REQUEST].mapping

        headers[LOCATION_HEADER] = location(headers, mapping.source_url) if headers[LOCATION_HEADER]

        rewrite_cookies(headers, substitute_domain: mapping.host) if headers[SET_COOKIE]

        [status, HttpHeaders.new(headers), body]
      end

      private

      def location(headers, source_url)
        location_header = headers[LOCATION_HEADER]
        path_directives.find(location_header).apply(location_header, source_url)
      end
    end
  end
end
