require 'sitehub/forward_proxies'
require 'sitehub/transaction_id'
require 'sitehub/middleware'
require 'sitehub/forward_proxy_builder'
require 'sitehub/reverse_proxy'
require 'rack/ssl-enforcer'
require 'sitehub/logging'
require 'rack/fiber_pool'
require 'logger'


class SiteHub

  class InvalidProxyDefinitionException < Exception;
  end
  class Builder

    attr_reader :sitehub, :forward_proxies, :reverse_proxies

    include Middleware

    def force_ssl except: []
      @force_ssl = true
      @ssl_exclusions = except
    end

    def initialize(&block)
      @forward_proxies = ForwardProxies.new
      @reverse_proxies = {}
      instance_eval &block if block
    end

    def access_logger logger=nil
      return @access_logger unless logger
      @access_logger = logger
    end

    def error_logger logger=nil
      return @error_logger unless logger
      @error_logger = logger
    end

    def sitehub_cookie_name name=nil
      @sitehub_cookie_name ||= RECORDED_ROUTES_COOKIE

      return @sitehub_cookie_name unless name
      @sitehub_cookie_name = name
    end

    def build
      forward_proxies.init
      use ReverseProxy, reverse_proxies
      use TransactionId
      use Logging::AccessLogger, access_logger || ::Logger.new(STDOUT)
      use Logging::ErrorLogger, error_logger || ::Logger.new(STDERR)
      use Rack::FiberPool
      use Rack::SslEnforcer, except: @ssl_exclusions if @force_ssl
      middlewares.reverse!

      apply_middleware(forward_proxies)
    end

    def proxy opts={}, &block
      args = {sitehub_cookie_name: sitehub_cookie_name}

      if opts.is_a?(Hash)
        mapped_path = opts.keys.first
        url = opts.values.first
        args.merge!(url: url, mapped_path: mapped_path)
      else
        args.merge!(mapped_path: opts)
      end

      forward_proxies << ForwardProxyBuilder.new(args, &block)
    end

    def reverse_proxy hash
      reverse_proxies.merge!(hash)
    end
  end

end