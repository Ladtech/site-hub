require 'sitehub/resolver'
class SiteHub
  class NilProxy
    include Resolver
    NOT_FOUND = Rack::Response.new(['page not found'], 404, {})

    def call env
      env[REQUEST] = Request.new(env: env, mapped_path: nil, mapped_url: nil)
      NOT_FOUND
    end
  end
end