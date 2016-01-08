require_relative '../collection'
class SiteHub
  class Collection < Hash
    class RouteCollection < Collection

      def add id, route, *opts
        self[id] = route
      end

      def valid?
        !self.empty?
      end

      def resolve(env: nil)
        return self.values.first unless self.values.find { |route| route.rule }
        result = self.values.find { |route| route.applies?(env) }
        result && result.resolve(env: env)
      end

      def transform &block
        each  do |id, value|
          self[id] = block.call(value)
        end
      end

    end
  end
end
