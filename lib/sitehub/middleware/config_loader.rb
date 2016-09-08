require 'active_support'
require 'sitehub/config_server'
class SiteHub
  module Middleware
    class ConfigLoader
      attr_reader :config_server, :app, :cache, :caching_options

      def initialize(_app, config_server_url, caching_options:)
        @config_server = ConfigServer.new(config_server_url)
        @cache = ActiveSupport::Cache::MemoryStore.new(size: 1.megabytes)
        @caching_options = caching_options
      end

      def call(env)
        begin
          load_config
        rescue ConfigServer::Error => e
          if @app
            env[ERRORS] << e.message
          else
            raise e unless @app
          end
        end

        @app.call env
      end

      # TODO: handle errors connecting to the config server
      def load_config
        unless cache.exist?(:sitehub_config)
          cache.write(:sitehub_config, :retrieved, caching_options)
          @app = Core.from_hash(config_server.get).build
        end
      end
    end
  end
end
