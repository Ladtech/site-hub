class SiteHub
  class CookieMiddleware

    include Rules, Resolver

    attr_reader :app, :sitehub_cookie_name, :sitehub_cookie_path, :id

    def initialize(app, sitehub_cookie_path: nil, sitehub_cookie_name:, id:, rule:)
      @app = app
      @sitehub_cookie_path = sitehub_cookie_path
      @sitehub_cookie_name = sitehub_cookie_name
      @id = id
      @rule = rule
    end

    def call env
      @app.call env
    end

    def == other
      other.app == self.app
    end
  end
end