require 'sitehub/middleware'
require 'sitehub/rules'

class SiteHub
  class Route
    include Middleware, Resolver, Rules, Equality

    attr_reader :id, :sitehub_cookie_name, :sitehub_cookie_path, :app

    def initialize(app, id:, sitehub_cookie_name:, sitehub_cookie_path: nil)
      @app = app
      @id = Identifier.new(id)
      @sitehub_cookie_name = sitehub_cookie_name
      @sitehub_cookie_path = sitehub_cookie_path
    end

    def call(env)
      request = env[REQUEST]
      @app.call(env).tap do |response|
        response.set_cookie(sitehub_cookie_name,
                            path: resolve_sitehub_cookie_path(request),
                            value: id)
      end
    end

    def resolve_sitehub_cookie_path(request)
      sitehub_cookie_path || request.path
    end

    def init
      @app = apply_middleware(@app)
      self
    end
  end
end
