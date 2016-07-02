class SiteHub
  class ForwardProxy
    include Equality

    attr_reader :downstream_client, :mapped_path, :mapped_url

    transient :downstream_client

    def initialize(mapped_path:, mapped_url:)
      @downstream_client = DownstreamClient.new
      @mapped_path = mapped_path
      @mapped_url = mapped_url
    end

    def call(env)
      request = env[REQUEST]
      request.map(mapped_path, mapped_url)

      downstream_client.call(request)
    end
  end
end
