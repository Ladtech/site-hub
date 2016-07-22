$LOAD_PATH.unshift(__dir__)
require 'middleware/logging'
require 'middleware/transaction_id'
require 'middleware/error_handling'
require 'middleware/candidate_routes'
require 'middleware/reverse_proxy'
require 'middleware/config_loader'
require 'rack/ssl-enforcer'
require 'middleware/route'
require 'rack/fiber_pool'

class SiteHub
  module Middleware
    def middlewares
      @middleware ||= []
    end

    def middleware?
      !middlewares.empty?
    end

    def use(middleware_clazz, *args, &block)
      middlewares << [middleware_clazz, args, block]
    end

    def apply_middleware(forward_proxy)
      middlewares.reverse.inject(forward_proxy) do |app, middleware_def|
        middleware, args, block = *middleware_def
        middleware.new(app, *args, &(block || proc {}))
      end
    end
  end
end
