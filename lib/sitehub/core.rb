require 'sitehub/getter_setter_methods'
require 'sitehub/forward_proxy_builder'

class SiteHub
  class InvalidProxyDefinitionException < Exception
  end

  class Core
    extend GetterSetterMethods

    getter_setter :sitehub_cookie_name, RECORDED_ROUTES_COOKIE
    attr_reader :forward_proxies, :reverse_proxies

    def initialize(&block)
      @forward_proxies = Middleware::ForwardProxies.new
      @reverse_proxies = {}
      instance_eval(&block) if block
    end

    def build
      Middleware::ReverseProxy.new(forward_proxies.init, reverse_proxies)
    end

    def proxy(opts = {}, &block)
      if opts.is_a?(Hash)
        mapped_path, url = *opts.to_a.flatten
      else
        mapped_path = opts
        url = nil
      end

      forward_proxies << ForwardProxyBuilder.new(sitehub_cookie_name: sitehub_cookie_name,
                                                 url: url,
                                                 mapped_path: mapped_path,
                                                 &block)
    end

    def reverse_proxy(hash)
      reverse_proxies.merge!(hash)
    end
  end
end
