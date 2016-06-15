require 'sitehub/constants'
require 'sitehub/resolver'
require 'rack/request'
require 'rack/response'
require 'rack/utils'
require 'em-http'

class SiteHub
  class ForwardProxies

    def call(env)
      source_request = Rack::Request.new(env)

      forward_proxy = mapped_route(path: source_request.path, request: source_request)

      return forward_proxy.call(env) if forward_proxy
      NOT_FOUND
    end

    def init
      forward_proxies.values.each(&:build)
      self
    end

    def <<(route)
      forward_proxies[route.mapped_path] = route
    end

    def mapped_route(path:, request:)
      fwd_proxy_builder = forward_proxies[mapping(path)]
      fwd_proxy_builder ? fwd_proxy_builder.resolve(id: request.cookies[RECORDED_ROUTES_COOKIE], env: request.env) : forward_proxies.default
    end

    def mapping(path)
      forward_proxies.keys.find do |key|
        case key
        when Regexp
          key.match(path)
        else
          path == key
        end
      end
    end

    class NilProxy
      include Resolver
      NOT_FOUND = Rack::Response.new(['page not found'], 404, {})
      def call env
        env[REQUEST] = Request.new(env: env, mapped_path: nil, mapped_url: nil)
        NOT_FOUND
      end
    end

    NIL_PROXY = NilProxy.new
    def forward_proxies
      @forward_proxies ||= begin
       {}.tap do|hash|
         hash.default = NIL_PROXY
       end
      end
    end
  end
end
