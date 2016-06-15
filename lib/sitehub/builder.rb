require 'sitehub/forward_proxies'
require 'sitehub/getter_setter_methods'
require 'sitehub/transaction_id'
require 'sitehub/error_handling'
require 'sitehub/middleware'
require 'sitehub/forward_proxy_builder'
require 'sitehub/reverse_proxy'
require 'rack/ssl-enforcer'
require 'sitehub/logging'
require 'rack/fiber_pool'
require 'logger'

class SiteHub
  class InvalidProxyDefinitionException < Exception
  end

  class Builder
    attr_reader :sitehub, :forward_proxies, :reverse_proxies

    include Middleware
    extend GetterSetterMethods

    getter_setters :access_logger, :error_logger
    getter_setter :sitehub_cookie_name, RECORDED_ROUTES_COOKIE

    def force_ssl(except: [])
      @force_ssl = true
      @ssl_exclusions = except
    end

    def initialize(&block)
      @forward_proxies = ForwardProxies.new
      @reverse_proxies = {}
      instance_eval(&block) if block
    end

    def build
      forward_proxies.init
      add_default_middleware
      middlewares.reverse!
      apply_middleware(forward_proxies)
    end

    def add_default_middleware
      use ReverseProxy, reverse_proxies
      use TransactionId
      use ErrorHandling
      use Logging::AccessLogger, access_logger || ::Logger.new(STDOUT)
      use Logging::ErrorLogger, error_logger || ::Logger.new(STDERR)
      use Rack::FiberPool
      use Rack::SslEnforcer, except: @ssl_exclusions if @force_ssl
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
