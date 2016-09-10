require 'uuid'
require 'sitehub/equality'
require 'sitehub/nil_route'
require 'sitehub/identifier'
require 'sitehub/getter_setter_methods'
require 'sitehub/candidate_routes/from_json'

require_relative 'collection/split_route_collection'
require_relative 'rules'
require_relative 'resolver'
require_relative 'collection/route_collection'
require_relative 'middleware'
require_relative 'forward_proxy'
require_relative 'downstream_client'

class SiteHub
  class TrackingCookieDefinition
    attr_reader :name, :path
    def initialize(name, path = nil)
      @name = name
      @path = path
    end
  end
  class CandidateRoutes
    class InvalidDefinitionError < StandardError
    end

    INVALID_PATH_MATCHER = 'Matcher for path (%s) was not a valid regexp: %s'.freeze
    class InvalidPathMatcherError < StandardError
    end

    ROUTES_WITH_SPLITS_MSG = 'you cant register routes and splits at the same level'.freeze
    INVALID_SPLIT_MSG = 'url must be defined if not supplying a block'.freeze
    RULE_NOT_SPECIFIED_MSG = 'rule must be supplied'.freeze
    PERCENTAGE_NOT_SPECIFIED_MSG = 'percentage must be supplied'.freeze
    IGNORING_URL_MSG = 'Block supplied, ignoring URL parameter'.freeze
    URL_REQUIRED_MSG = 'URL must be supplied for splits and routes'.freeze

    extend CollectionMethods, FromJson, GetterSetterMethods
    include Rules, Equality, Middleware, CollectionMethods

    getter_setters :sitehub_cookie_path, :sitehub_cookie_name
    attr_reader :id, :mapped_path

    def add(label:, rule: nil, percentage: nil, url: nil, &block)
      child_label = id.child_label(label)

      route = if block
                raise InvalidDefinitionError, candidate_definition_msg unless percentage || rule
                warn(IGNORING_URL_MSG) if url
                new(rule: rule, id: child_label, &block).build
              else
                raise InvalidDefinitionError, URL_REQUIRED_MSG unless url
                forward_proxy(url: url, label: child_label, rule: rule)
              end

      candidates.add(Identifier.new(label), route, percentage)
    end

    def build
      build_with_middleware if middleware?
      self
    end

    def candidates(clazz = nil)
      return @endpoints ||= Collection::RouteCollection.new unless clazz
      @endpoints ||= clazz.new

      raise InvalidDefinitionError, ROUTES_WITH_SPLITS_MSG unless @endpoints.is_a?(clazz)
      @endpoints
    end

    def default(url:)
      candidates.default = forward_proxy(label: :default, url: url)
    end

    def default_route
      candidates.default
    end

    def default_route?
      !default_route.nil?
    end

    def forward_proxy(label:, url:, rule: nil)
      proxy = ForwardProxy.new(mapped_url: url, mapped_path: mapped_path)

      Route.new(proxy,
                id: label,
                sitehub_cookie_path: sitehub_cookie_path,
                sitehub_cookie_name: sitehub_cookie_name).tap do |wrapper|
        wrapper.rule(rule)
      end
    end

    # TODO: combine cookie name and path in to an : nobject
    def initialize(id: nil, version_cookie:, mapped_path:, rule: nil, &block)
      @id = Identifier.new(id)

      @mapped_path = sanitise_mapped_path(mapped_path)
      sitehub_cookie_name(version_cookie.name)
      sitehub_cookie_path(version_cookie.path)

      rule(rule)

      init(&block) if block_given?
    end

    def resolve(id: nil, env:)
      id = Identifier.new(id)
      if id.valid? && (route = candidates[id.root])
        route.resolve(id: id.sub_id, env: env)
      else
        candidates.resolve(env: env) || default_route
      end
    end

    def route(url: nil, label:, rule: nil, &block)
      candidates(Collection::RouteCollection)
      add(label: label, rule: rule, url: url, &block)
    end

    def split(percentage:, url: nil, label:, &block)
      candidates(Collection::SplitRouteCollection)
      add(label: label, percentage: percentage, url: url, &block)
    end

    def valid?
      return true if default_route?
      candidates.valid?
    end

    def [](key)
      candidates[Identifier.new(key)]
    end

    def string_containing_regexp?(obj)
      return false unless obj.is_a?(String)
      obj.start_with?('%r{') && obj.end_with?('}')
    end

    def string_to_regexp(mapped_path)
      regexp_string = mapped_path.to_s.sub(/^%r{/, '').sub(/}$/, '')
      Regexp.compile(regexp_string)
    rescue RegexpError => e
      raise InvalidPathMatcherError, format(INVALID_PATH_MATCHER, regexp_string, e.message)
    end

    private

    def add_middleware_to_proxy(proxy)
      middlewares.each do |middleware_args_and_block|
        middleware_class, args, block = middleware_args_and_block
        proxy.use middleware_class, *args, &block
      end
    end

    def build_with_middleware
      routes = candidates.values.find_all { |route| route.is_a?(Route) }

      routes << default_route if default_route?

      routes.each do |route|
        add_middleware_to_proxy(route)
        route.init
      end
    end

    def candidate_definition_msg
      splits? ? PERCENTAGE_NOT_SPECIFIED_MSG : RULE_NOT_SPECIFIED_MSG
    end

    def init(&block)
      instance_eval(&block)
      raise InvalidDefinitionError unless valid?
    end

    def new(id:, rule: nil, &block)
      inherited_middleware = middlewares

      self.class.new(id: id,
                     version_cookie: TrackingCookieDefinition.new(sitehub_cookie_name, sitehub_cookie_path),
                     mapped_path: mapped_path,
                     rule: rule) do
        middlewares.concat(inherited_middleware)
        instance_eval(&block)
      end
    end

    def sanitise_mapped_path(mapped_path)
      string_containing_regexp?(mapped_path) ? string_to_regexp(mapped_path) : mapped_path
    end

    def splits?
      candidates.is_a?(Collection::SplitRouteCollection)
    end
  end
end
