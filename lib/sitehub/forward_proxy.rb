# rubocop:disable Metrics/ParameterLists
class SiteHub
  class ForwardProxy
    include Rules, Resolver

    attr_reader :downstream_client, :sitehub_cookie_name, :sitehub_cookie_path, :id, :mapped_path, :mapped_url

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

      response = downstream_client.call(request)
      value = request.cookies[sitehub_cookie_name.to_s] || id
      response.set_cookie(sitehub_cookie_name, path: resolve_sitehub_cookie_path(request), value: value)
      response
    end

    def resolve_sitehub_cookie_path(request)
      sitehub_cookie_path || request.path
    end

    def ==(other)
      expected = [other.mapped_path,
                  other.mapped_url,
                  other.rule,
                  other.id,
                  other.sitehub_cookie_name,
                  other.sitehub_cookie_path]

      expected == [mapped_path, mapped_url, rule, id, sitehub_cookie_name, sitehub_cookie_path]
    end
  end
end
