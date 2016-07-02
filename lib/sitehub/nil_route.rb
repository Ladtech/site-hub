require 'sitehub/resolver'
class SiteHub
  class NilRoute
    include Resolver
    NOT_FOUND = Rack::Response.new(['page not found'], 404, {})

    def call(_env)
      NOT_FOUND
    end
  end
end
