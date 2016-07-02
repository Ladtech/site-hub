require 'uuid'
require 'sitehub/equality'
require 'sitehub/getter_setter_methods'
require_relative 'collection/split_route_collection'
require_relative 'rules'
require_relative 'resolver'
require_relative 'collection/route_collection'
require_relative 'middleware'
require_relative 'forward_proxy'
require_relative 'downstream_client'

class SiteHub
  class RouteBuilder
    class InvalidDefinitionException < Exception
    end

    INVALID_SPLIT_MSG = 'url must be defined if not supplying a block'.freeze
    ROUTES_WITH_SPLITS_MSG = 'you cant register routes and splits at the same level'.freeze
    INVALID_ROUTE_DEF_MSG = 'rule must be specified when supplying a block'.freeze
    IGNORING_URL_LABEL_MSG = 'Block supplied, ignoring URL and Label parameters'.freeze
    URL_REQUIRED_MSG = 'URL must be supplied for splits and routes'.freeze

    class << self
      # TODO: support nest splits and routes
      def from_hash(hash, sitehub_cookie_name)
        new(mapped_path: hash[:path]) do
          sitehub_cookie_name sitehub_cookie_name
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

    getter_setters :default_proxy, :sitehub_cookie_path, :sitehub_cookie_name
    attr_reader :mapped_path, :id

    def initialize(mapped_path:, rule: nil, &block)
      @id = UUID.generate(:compact)
      @mapped_path = mapped_path
      @splits = Collection::SplitRouteCollection.new
      @routes = Collection::RouteCollection.new
      rule(rule)

      return unless block_given?

      instance_eval(&block)
      raise InvalidDefinitionException unless valid?
    end

    def build
      if middleware?
        build_with_middleware
        build_default_with_middleware if default_proxy
      end

      self
    end

    def default(url:)
      default_proxy(forward_proxy(label: :default, url: url))
    end

    def endpoints(collection = nil)
      return @endpoints || Collection::RouteCollection.new unless collection

      raise InvalidDefinitionException, ROUTES_WITH_SPLITS_MSG if @endpoints && @endpoints != collection
      @endpoints = collection
    end

    def forward_proxy(label:, url:, rule: nil)
      proxy = ForwardProxy.new(mapped_url: url, mapped_path: mapped_path)

      id = (label || UUID.generate(:compact)).to_sym
      Route.new(proxy,
                id: id,
                sitehub_cookie_path: sitehub_cookie_path,
                sitehub_cookie_name: sitehub_cookie_name).tap do |wrapper|
        wrapper.rule(rule)
      end
    end

    def resolve(id: nil, env:)
      id = id.to_s.to_sym
      endpoints[id] || endpoints.resolve(env: env) || default_proxy
    end

    def route(url: nil, label: nil, rule: nil, &block)
      endpoint = if block
                   raise InvalidDefinitionException, INVALID_ROUTE_DEF_MSG unless rule
                   warn(IGNORING_URL_LABEL_MSG) if url || label
                   new(rule: rule, &block).build
                 else
                   forward_proxy(url: url, label: label, rule: rule)
                 end

      routes.add(endpoint.id, endpoint)
    end


    def split(percentage:, url: nil, label: nil, &block)
      raise InvalidDefinitionException, INVALID_SPLIT_MSG unless block || url

      proxy = if block
                warn(IGNORING_URL_LABEL_MSG) if url || label
                new(&block).build
              else
                forward_proxy(label: label, url: url)
              end

      splits.add proxy.id, proxy, percentage
    end

    def valid?
      return true if default_proxy
      endpoints.valid?
    end

    private

    def add_middleware_to_proxy(proxy)
      middlewares.each do |middleware_args_and_block|
        middleware_class, args, block = middleware_args_and_block
        proxy.use middleware_class, *args, &block
      end
    end


    def build_default_with_middleware
      add_middleware_to_proxy(default_proxy)
      default_proxy.init
    end

    def build_with_middleware
      endpoints.values.each do |proxy|
        add_middleware_to_proxy(proxy)
        proxy.init
      end
    end

    def new(rule: nil, &block)
      self.class.new(mapped_path: mapped_path, rule: rule, &block).tap do |builder|
        builder.sitehub_cookie_name sitehub_cookie_name
        builder.sitehub_cookie_path sitehub_cookie_path
      end
    end

    def splits
      endpoints(@splits)
    end

    def routes
      endpoints(@routes)
    end

  end
end
