require_relative '../collection'
# rubocop:disable Lint/UnusedMethodArgument -
# this is because #resolve is supporting a duck typed interface and needs the env parameter

class SiteHub
  class Collection < Hash
    class RouteCollection < Collection
      def add(id, route, *_opts)
        self[id] = route
      end

      def valid?
        !keys.empty?
      end

      def resolve(id: nil, env: nil)
        return values.first unless values.find(&:rule)
        result = values.find { |route| route.applies?(env) }
        result && result.resolve(env: env)
      end
    end
  end
end
