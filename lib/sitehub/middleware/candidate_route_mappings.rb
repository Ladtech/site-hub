require 'sitehub/getter_setter_methods'
require 'sitehub/constants'
require 'sitehub/nil_route'
require 'rack/request'
require 'rack/response'
require 'rack/utils'
require 'em-http'

class SiteHub
  module Middleware
    class CandidateRouteMappings < Hash
      NIL_ROUTE = NilRoute.new

      include Equality

      extend GetterSetterMethods
      getter_setter :sitehub_cookie_name, RECORDED_ROUTES_COOKIE

      def initialize
        self.default = NIL_ROUTE
      end

      def call(env)
        source_request = Rack::Request.new(env)

        route = mapped_route(path: source_request.path, request: source_request)

        route.call(env)
      end

      def init
        values.each(&:build)
        self
      end

      def add_route(url: nil, mapped_path: nil, candidate_routes: nil, &block)
        unless candidate_routes
          candidate_routes = CandidateRoutes.new(sitehub_cookie_name: sitehub_cookie_name,
                                                 mapped_path: mapped_path,
                                                 &block).tap do |builder|
            builder.default(url: url) if url
          end
        end

        self[candidate_routes.mapped_path] = candidate_routes
      end

      def mapped_route(path:, request:)
        self[mapping(path)].resolve(id: request.cookies[sitehub_cookie_name], env: request.env)
      end

      def mapping(path)
        keys.find do |key|
          case key
          when Regexp
            key.match(path)
          else
            path == key
          end
        end
      end
    end
  end
end
