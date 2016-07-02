class SiteHub
  class ConfigServer
    attr_reader :server_url, :http_client
    def initialize(url)
      @server_url = url
      @http_client = Faraday.new(ssl: { verify: false }) do |con|
        con.adapter :em_synchrony
      end
    end

    def get
      JSON(http_client.get(server_url).body, symbolize_names: true)
    end
  end

  module Middleware
    class ConfigLoader
      attr_reader :config_server, :app, :cache

      def initialize(_app, config_server_url)
        @config_server = ConfigServer.new(config_server_url)
        @cache = ActiveSupport::Cache::MemoryStore.new(size: 1.megabytes)
      end

      def call(env)
        load_config
        @app.call env
      end

      def load_config
        config = cache.fetch(:sitehub_config, expires_in: 30) do
          config_server.get
        end

        @app = Core.from_hash(config).build
      end
    end
  end
end
