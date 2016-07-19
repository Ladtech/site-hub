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

    ROUTES_WITH_SPLITS_MSG = 'you cant register routes and splits at the same level'.freeze
    INVALID_SPLIT_MSG = 'url must be defined if not supplying a block'.freeze
    RULE_NOT_SPECIFIED_MSG = 'rule must be specified when supplying a block'.freeze
    IGNORING_URL_MSG = 'Block supplied, ignoring URL parameter'.freeze
    URL_REQUIRED_MSG = 'URL must be supplied for splits and routes'.freeze

    class << self
      # TODO: support nest splits and routes
      def from_hash(hash, sitehub_cookie_name)
        new(sitehub_cookie_name: sitehub_cookie_name, sitehub_cookie_path: hash[:sitehub_cookie_path], mapped_path: hash[:path]) do
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

    def initialize(id: nil, sitehub_cookie_name:, sitehub_cookie_path: nil, mapped_path:, rule: nil, &block)
      @id = id.to_s.to_sym
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

    def routes(collection = nil)
      return @endpoints ||= Collection::RouteCollection.new unless collection

      raise InvalidDefinitionException, ROUTES_WITH_SPLITS_MSG if @endpoints && !@endpoints.equal?(collection)
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
      parts = id.to_s.split('|').delete_if { |part| part == self.id.to_s }.collect(&:to_sym)
      first = parts.delete_at(0)
      resolved = routes[first]
      result = resolved ? resolved.resolve(id: parts.join('|'), env: env) : routes.resolve(env: env)
      result || default_proxy
    end

    def route(url: nil, label:, rule: nil, &block)
      routes(@routes)
      add_route(label: label, rule: rule, url: url, &block)
    end

    def split(percentage:, url: nil, label:, &block)
      routes(@splits)
      add_route(label: label, percentage: percentage, url: url, &block)
    end

    def add_route(label:, rule: nil, percentage: nil, url: nil, &block)
      raise if rule && percentage

      route = if block
                   unless percentage
                     raise InvalidDefinitionException, RULE_NOT_SPECIFIED_MSG unless rule
                   end

                   warn(IGNORING_URL_MSG) if url
                   new(rule: rule, id: label, &block).build.routes
                 else
                   raise InvalidDefinitionException, RULE_NOT_SPECIFIED_MSG unless url
                   forward_proxy(url: url, label: generate_label(label), rule: rule)
                 end

      routes.add(label, route, percentage)
    end

    def generate_label(label)
      self.id ? "#{self.id}|#{label}" : label
    end

    def valid?
      return true if default_proxy
      routes.valid?
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
      routes.values.each do |proxy|
        add_middleware_to_proxy(proxy)
        proxy.init
      end
    end

    def new(id:, rule: nil, &block)
      self.class.new(id: id,
                     sitehub_cookie_name: sitehub_cookie_name,
                     sitehub_cookie_path: sitehub_cookie_path,
                     mapped_path: mapped_path,
                     rule: rule,
                     &block)
    end
  end
end
