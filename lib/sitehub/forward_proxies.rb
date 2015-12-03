require 'sitehub/constants'
require 'sitehub/forward_proxy'
require 'rack/request'
require 'rack/response'
require 'rack/utils'
require 'em-http'

class SiteHub
  class ForwardProxies

    NOT_FOUND = Rack::Response.new(['page not found'], 404, {})
    def call env
      source_request = Rack::Request.new(env)

      forward_proxy = mapped_route(path: source_request.path, request: source_request)

      return forward_proxy.call(env) if forward_proxy
      NOT_FOUND
    end

    def init
      forward_proxies.values.each { |proxy| proxy.build }
      self
    end

    def << route
      forward_proxies[route.mapped_path] = route
    end

    def mapped_route(path:, request:)

      key = forward_proxies.keys.find do |key|
        case key
          when Regexp
            key.match(path)
          else
            path == key
        end
      end

      forward_proxy_builder = forward_proxies[key]
      forward_proxy_builder ? forward_proxy_builder.resolve(id: request.cookies[RECORDED_ROUTES_COOKIE], env: request.env) : nil
    end

    def forward_proxies
      @forward_proxies ||= {}
    end

  end
end
