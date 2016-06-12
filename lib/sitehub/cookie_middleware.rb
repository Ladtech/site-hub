class SiteHub
  class CookieMiddleware
    include Rules, Resolver

    attr_reader :downstream_client, :sitehub_cookie_name, :sitehub_cookie_path, :id

    def initialize(app, sitehub_cookie_path: nil, sitehub_cookie_name:, id:, rule: nil)
      @downstream_client = app
      @sitehub_cookie_path = sitehub_cookie_path
      @sitehub_cookie_name = sitehub_cookie_name
      @id = id
      @rule = rule
    end

    def call(env)
      status, headers, body = downstream_client.call(env).to_a

      source_request = Rack::Request.new(env)
      Rack::Response.new(body, status, headers).tap do |response|
        response.set_cookie(sitehub_cookie_name, path: (sitehub_cookie_path || source_request.path), value: id)
      end
    end

    def ==(other)
      other.downstream_client == downstream_client
    end
  end
end
