class SiteHub
  module Middleware
    def middlewares
      @middleware ||= []
    end

    def use(middleware_clazz, *args, &block)
      middlewares << [middleware_clazz, args, block|| proc{}]
    end

    def apply_middleware(forward_proxy)
      middlewares.reverse.inject(forward_proxy) do |app, middleware_def|
        middleware = middleware_def[0]
        args = middleware_def[1] || []
        block = middleware_def[2] || proc {}

        middleware.new(app, *args, &block)
      end
    end
  end
end