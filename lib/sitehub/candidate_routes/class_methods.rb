class SiteHub
  class CandidateRoutes
    module ClassMethods
      extend CollectionMethods

      # TODO: support nested routes, i.e. support rule name being passed in
      def from_hash(hash, sitehub_cookie_name)
        new(sitehub_cookie_name: sitehub_cookie_name,
            sitehub_cookie_path: hash[:sitehub_cookie_path],
            mapped_path: hash[:path], calling_scope: self) do
          handle_routes(hash, self)
          default url: hash[:default] if hash[:default]
        end
      end

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
          if split[:splits] || split[:routes]
            routes.split(percentage: split[:percentage], label: split[:label]) do
              handle_routes(split, self)
            end
          else
            routes.split(percentage: split[:percentage], label: split[:label], url: split[:url])
          end
        end
      end
    end
  end
end
