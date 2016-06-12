require 'uuid'
require_relative 'collection/split_route_collection'
require_relative 'rules'
require_relative 'resolver'
require_relative 'collection/route_collection'
require_relative 'middleware'
require_relative 'forward_proxy'
require_relative 'downstream_client'

class SiteHub
  class ForwardProxyBuilder
    include Middleware
    include Rules, Resolver

    class InvalidDefinitionException < Exception
    end

    INVALID_SPLIT_MSG = 'label and url must be defined if not supplying a block'.freeze
    ROUTES_WITH_SPLITS_MSG = 'you cant register routes and splits at the same level'.freeze
    INVALID_ROUTE_DEF_MSG = 'rule must be specified when supplying a block'.freeze

    attr_reader :mapped_path, :default_proxy, :routes, :middlewares, :splits, :sitehub_cookie_name

    def initialize(url: nil, mapped_path:, rule: nil, sitehub_cookie_name: nil, &block)
      @mapped_path = mapped_path
      @middlewares = []
      @splits = Collection::SplitRouteCollection.new
      @routes = Collection::RouteCollection.new
      @sitehub_cookie_name = sitehub_cookie_name
      rule(rule) if rule
      default(url: url) if url

      return unless block

      instance_eval(&block)
      raise InvalidDefinitionException unless valid?
    end

    def valid?
      return true if @default_proxy
      endpoints.valid?
    end

    def endpoints(collection = nil)
      return @endpoints || Collection::RouteCollection.new unless collection

      raise InvalidDefinitionException, ROUTES_WITH_SPLITS_MSG if @endpoints && @endpoints != collection
      @endpoints = collection
    end

    def split(percentage:, url: nil, label: nil, &block)
      endpoints(splits)

      raise InvalidDefinitionException, INVALID_SPLIT_MSG unless block || [url, label].all?

      label = label ? label.to_sym : UUID.generate(:compact)

      proxy = block ? new(&block).build : forward_proxy(label: label, url: url)

      endpoints.add label, proxy, percentage
    end

    def new(&block)
      self.class.new(mapped_path: mapped_path, &block)
    end

    def route(url: nil, label: nil, rule: nil, &block)
      endpoints(routes)

      if block
        raise InvalidDefinitionException, INVALID_ROUTE_DEF_MSG unless rule
        builder = self.class.new(mapped_path: mapped_path, rule: rule, &block).build
        endpoints.add UUID.generate(:compact), builder
      else
        endpoints.add label.to_sym, forward_proxy(url: url, label: label, rule: rule)
      end
    end

    def default(url:)
      @default_proxy = forward_proxy(label: :default, url: url)
    end

    def sitehub_cookie_path(path = nil)
      return @sitehub_cookie_path unless path
      @sitehub_cookie_path = path
    end

    def build
      endpoints.transform do |proxy|
        apply_middleware(proxy).tap do |wrapped_proxy|
          wrapped_proxy.extend(Rules)
          wrapped_proxy.extend(Resolver) unless wrapped_proxy.is_a?(Resolver)
          wrapped_proxy.rule(proxy.rule)
        end
      end
      @default_proxy = apply_middleware(default_proxy) if default_proxy
      self
    end

    def resolve(id: nil, env:)
      id = id.to_s.to_sym
      endpoints[id] || endpoints.resolve(env: env) || default_proxy
    end

    def ==(other)
      other.is_a?(ForwardProxyBuilder) && default_proxy == other.default_proxy && endpoints == other.endpoints
    end

    def forward_proxy(label:, url:, rule: nil)
      ForwardProxy.new(sitehub_cookie_path: sitehub_cookie_path,
                       sitehub_cookie_name: sitehub_cookie_name,
                       id: label.to_sym,
                       rule: rule,
                       mapped_url: url,
                       mapped_path: mapped_path)
    end
  end
end
