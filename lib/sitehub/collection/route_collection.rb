require_relative '../collection'
class SiteHub
  class Collection < Hash
    class RouteCollection < Collection
      def add(id, route, *_opts)
        self[id] = route
      end

      def valid?
        !empty?
      end

      def resolve(env: nil)
        return values.first unless values.find(&:rule)
        result = values.find { |route| route.applies?(env) }
        result && result.resolve(env: env)
      end
    end
  end
end
