require 'logger'
require 'sitehub/core'

class SiteHub
  class Builder
    attr_reader :core

    include Middleware
    extend GetterSetterMethods

    getter_setters :access_logger, :error_logger

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
      middlewares.reverse!
      apply_middleware(core.build)
    end

    def add_default_middleware
      use Middleware::TransactionId
      use Middleware::ErrorHandling
      use Middleware::Logging::AccessLogger, access_logger || ::Logger.new(STDOUT)
      use Middleware::Logging::ErrorLogger, error_logger || ::Logger.new(STDERR)
      use Rack::FiberPool
      use Rack::SslEnforcer, except: @ssl_exclusions if @force_ssl
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
