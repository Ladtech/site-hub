require 'logger'
require 'sitehub/core'
require 'active_support/cache'

class SiteHub
  class Builder
    include Middleware
    extend GetterSetterMethods

    DEFAULT_CACHING_OPTIONS = { expires_in: 30 }.freeze

    attr_reader :core, :config_server_url, :config_server_caching_options
    getter_setters :access_logger, :error_logger

    def config_server(url, caching_options: DEFAULT_CACHING_OPTIONS)
      @config_server_url = url
      @config_server_caching_options = caching_options
    end

    def force_ssl(except: [])
      @force_ssl = true
      @ssl_exclusions = except
    end

    def initialize(&block)
      @core = Core.new
      instance_eval(&block) if block
    end

    def build
      add_default_middleware
      use ConfigLoader, config_server_url, caching_options: config_server_caching_options if config_server_url
      apply_middleware(core.build)
    end

    def add_default_middleware
      use Rack::SslEnforcer, except: @ssl_exclusions if @force_ssl
      use Rack::FiberPool
      use Middleware::Logging::ErrorLogger, error_logger || ::Logger.new(STDERR)
      use Middleware::Logging::AccessLogger, access_logger || ::Logger.new(STDOUT)
      use Middleware::ErrorHandling
      use Middleware::TransactionId
    end

    def respond_to?(method)
      super || core.respond_to?(method)
    end

    def method_missing(method, *args, &block)
      core.send(method, *args, &block)
    rescue NoMethodError
      super
    end
  end
end
