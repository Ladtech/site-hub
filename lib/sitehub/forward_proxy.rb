# rubocop:disable Metrics/ParameterLists
class SiteHub
  class ForwardProxy
    include Rules, Resolver, Equality

    attr_reader :downstream_client, :sitehub_cookie_name, :id, :sitehub_cookie_path, :mapped_path, :mapped_url

    transient :downstream_client

    def initialize(sitehub_cookie_path: nil, sitehub_cookie_name:, id:, rule: nil, mapped_path:, mapped_url:)
      @downstream_client = DownstreamClient.new
      @sitehub_cookie_path = sitehub_cookie_path
      @sitehub_cookie_name = sitehub_cookie_name
      @id = id
      @rule = rule
      @mapped_path = mapped_path
      @mapped_url = mapped_url
    end

    def call(env)
      request = env[REQUEST]
      request.map(mapped_path, mapped_url)

      downstream_client.call(request).tap do |response|
        response.set_cookie(sitehub_cookie_name,
                            path: resolve_sitehub_cookie_path(request),
                            value: id)
      end
    end

    def resolve_sitehub_cookie_path(request)
      sitehub_cookie_path || request.path
    end
  end
end
