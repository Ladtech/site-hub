class SiteHub
  class CookieMiddleware

    include Rules, Resolver

    attr_reader :app, :sitehub_cookie_name, :sitehub_cookie_path, :id

    def initialize(app, sitehub_cookie_path: nil, sitehub_cookie_name:, id:, rule: nil)
      @app = app
      @sitehub_cookie_path = sitehub_cookie_path
      @sitehub_cookie_name = sitehub_cookie_name
      @id = id
      @rule = rule
    end

    def call env
      status, headers, body = @app.call(env).to_a

      source_request = Rack::Request.new(env)
      Rack::Response.new(body, status, headers).tap do |response|
        response.set_cookie(sitehub_cookie_name, path: (sitehub_cookie_path || source_request.path), value: id)
      end
    end

    def == other
      other.app == self.app
    end
  end
end