require 'uuid'
require 'sitehub/equality'
require 'sitehub/nil_route'
require 'sitehub/identifier'
require 'sitehub/getter_setter_methods'
require_relative 'collection/split_route_collection'
require_relative 'rules'
require_relative 'resolver'
require_relative 'collection/route_collection'
require_relative 'middleware'
require_relative 'forward_proxy'
require_relative 'downstream_client'

class SiteHub
  class CandidateRoutes
    class InvalidDefinitionException < Exception
    end

    #TODO - correct messaging
    ROUTES_WITH_SPLITS_MSG = 'you cant register routes and splits at the same level'.freeze
    INVALID_SPLIT_MSG = 'url must be defined if not supplying a block'.freeze
    RULE_NOT_SPECIFIED_MSG = 'rule must be supplied'.freeze
    PERCENTAGE_NOT_SPECIFIED_MSG = 'percentage must be supplied'.freeze
    IGNORING_URL_MSG = 'Block supplied, ignoring URL parameter'.freeze
    URL_REQUIRED_MSG = 'URL must be supplied for splits and routes'.freeze

    class << self
      # TODO: support nest splits and routes
      def from_hash(hash, sitehub_cookie_name)
        new(sitehub_cookie_name: sitehub_cookie_name,
            sitehub_cookie_path: hash[:sitehub_cookie_path],
            mapped_path: hash[:path]) do
          extend CollectionMethods

          collection(hash, :splits).each do |split|
            split(percentage: split[:percentage], url: split[:url], label: split[:label])
          end

          collection(hash, :routes).each do |route|
            route(url: route[:url], label: route[:label])
          end

          default url: hash[:default] if hash[:default]
        end
      end
    end

    extend GetterSetterMethods
    include Rules, Equality, Middleware

    transient :id

    getter_setters :sitehub_cookie_path, :sitehub_cookie_name
    attr_reader :mapped_path, :id

    def initialize(id: nil, sitehub_cookie_name:, sitehub_cookie_path: nil, mapped_path:, rule: nil, &block)
      @id = Identifier.new(id)
      @mapped_path = mapped_path
      @sitehub_cookie_name = sitehub_cookie_name
      @sitehub_cookie_path = sitehub_cookie_path
      @splits = Collection::SplitRouteCollection.new
      @routes = Collection::RouteCollection.new
      rule(rule)

      return unless block_given?

      instance_eval(&block)
      raise InvalidDefinitionException unless valid?
    end

    def add_route(label:, rule: nil, percentage: nil, url: nil, &block)
      child_label = id.child_label(label)

      route = if block
                #TODO test for messages
                message = splits? ? PERCENTAGE_NOT_SPECIFIED_MSG : RULE_NOT_SPECIFIED_MSG
                raise InvalidDefinitionException, message unless percentage || rule
                warn(IGNORING_URL_MSG) if url
                new(rule: rule, id: child_label, &block).build
              else
                raise InvalidDefinitionException, URL_REQUIRED_MSG unless url
                forward_proxy(url: url, label: child_label, rule: rule)
              end

      routes.add(Identifier.new(label), route, percentage)
    end

    def [] key
      routes[Identifier.new(key)]
    end

    def default_route
      routes.default
    end

    def default_route?
      !default_route.nil?
    end

    def build
      build_with_middleware if middleware?
      self
    end

    def default(url:)
      routes.default = forward_proxy(label: :default, url: url)
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

    def resolve(id: nil, env:)
      id = Identifier.new(id)
      if id.valid? && (route = routes[id.root])
        route.resolve(id: id.sub_id, env: env)
      else
        routes.resolve(env: env) || default_route
      end
    end

    def route(url: nil, label:, rule: nil, &block)
      routes(@routes)
      add_route(label: label, rule: rule, url: url, &block)
    end

    def routes(collection = nil)
      return @endpoints ||= Collection::RouteCollection.new unless collection

      raise InvalidDefinitionException, ROUTES_WITH_SPLITS_MSG if @endpoints && !@endpoints.equal?(collection)
      @endpoints = collection
    end

    def split(percentage:, url: nil, label:, &block)
      routes(@splits)
      add_route(label: label, percentage: percentage, url: url, &block)
    end

    def splits?
      routes.is_a?(Collection::SplitRouteCollection)
    end

    def valid?
      return true if default_route?
      routes.valid?
    end

    private

    def add_middleware_to_proxy(proxy)
      middlewares.each do |middleware_args_and_block|
        middleware_class, args, block = middleware_args_and_block
        proxy.use middleware_class, *args, &block
      end
    end

    def build_with_middleware
      routes = routes().values.find_all { |route| route.is_a?(Route) }

      routes << default_route if default_route?

      routes.each do |route|
        add_middleware_to_proxy(route)
        route.init
      end
    end

    def new(id:, rule: nil, &block)
      inherited_middleware = middlewares()

      self.class.new(id: id,
                     sitehub_cookie_name: sitehub_cookie_name,
                     sitehub_cookie_path: sitehub_cookie_path,
                     mapped_path: mapped_path,
                     rule: rule) do
        middlewares.concat(inherited_middleware)
        instance_eval(&block)
      end
    end
  end
end
