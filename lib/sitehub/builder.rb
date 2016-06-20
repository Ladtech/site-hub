require 'logger'
require 'sitehub/core'

class SiteHub
  class ConfigServer
    def initialize url
    end

    def get
      {
          proxies: [
              {
                  path: '/route_1',
                  sitehub_cookie_path: '/some/path',
                  sitehub_cookie_name: 'custom_cookie_name',

                  splits: [
                      {
                          percentage: 50,
                          label: :label_1,
                          url: 'http://lvl-up.uk/'
                      },
                      {
                          percentage: 50,
                          label: :label_2,
                          url: 'http://lvl-up.uk/'
                      }
                  ],
                  routes:{},
                  default: 'http://lvl-up.uk/'
              },

              {
                  path: '/route_2',

                  splits:{},
                  routes: [
                      {
                          label: :label_1,
                          rule: proc{false},
                          url: 'http://lvl-up.uk/'
                      },
                  ],
                  default: 'http://lvl-up.uk/'
              }
          ],

          reverse_proxies: [
              {downstream_url: 'http://downstream/url1', path: '/rewritten/path1'},
              {downstream_url: 'http://downstream/url2', path: '/rewritten/path2'}
          ]
      }
    end
  end

  class ConfigLoader

    attr_reader :config_server, :app
    def initialize app, config_server_url
      @config_server = ConfigServer.new(config_server_url)
      config = config_server.get
      @app = Core.new do
        config[:proxies].each do |proxy|
          proxy(proxy[:path]) do
            proxy[:splits].each do |split|
              split(percentage: split[:percentage], url: split[:url], label: split[:label])
            end

            proxy[:routes].each do |route|
              route(url: route[:url], label: route[:label])
            end

            default url: proxy[:default] if proxy[:default]
          end
        end
      end.build
    end

    def call env
      @app.call env
    end
  end

  class Builder
    attr_reader :core

    include Middleware
    extend GetterSetterMethods

    getter_setters :access_logger, :error_logger, :config_server

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
      use ConfigLoader, config_server if config_server
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
