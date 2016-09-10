class SiteHub
  class CandidateRoutes
    module FromJson
      extend CollectionMethods

      def self.extended(clazz)
        clazz.class_eval do
          include InstanceMethods
        end
      end

      # TODO: support nested routes, i.e. support rule name being passed in
      def from_hash(hash, sitehub_cookie_name, sitehub_cookie_path)
        cookie_path = hash[:sitehub_cookie_path] || sitehub_cookie_path
        cookie_name = hash[:sitehub_cookie_name] || sitehub_cookie_name
        new(version_cookie: TrackingCookieDefinition.new(cookie_name, cookie_path),
            mapped_path: hash[:path]) do
          handle_routes(hash, self)
          default url: hash[:default] if hash[:default]
        end
      end

      module InstanceMethods
        private

        def handle_routes(hash, routes)
          extract_splits(hash, routes)
          extract_routes(hash, routes)
        end

        def extract_routes(hash, routes)
          collection(hash, :routes).each do |route|
            routes.route(url: route[:url], label: route[:label])
          end
        end

        def extract_splits(hash, routes)
          collection(hash, :splits).each do |split|
            label = split[:label]
            percentage = split[:percentage]
            cookie_name = split[:sitehub_cookie_name] || sitehub_cookie_name

            if split[:splits] || split[:routes]
              routes.split(percentage: percentage, label: label) { handle_routes(split, self) }
            else
              routes.split(percentage: percentage, label: label, url: split[:url])
            end
          end
        end
      end
    end
  end
end
