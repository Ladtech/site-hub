require 'sitehub/candidate_routes'
require 'forwardable'

class SiteHub
  class InvalidProxyDefinitionException < Exception
  end

  class ConfigError < Exception
  end

  module CollectionMethods
    def collection(hash, item)
      hash[item] || []
    end

    def collection!(hash, item)
      return hash[item] if hash[item]
      raise ConfigError, "missing: #{item}"
    end
  end

  class Core
    class << self
      # TODO: default action for missing key, throw exception?
      def from_hash(config)
        new do
          extend CollectionMethods
          sitehub_cookie_name config[:sitehub_cookie_name] if config[:sitehub_cookie_name]

          collection!(config, :proxies).each do |proxy|
            mappings.add_route route_builder: CandidateRoutes.from_hash(proxy, sitehub_cookie_name)
          end

          collection(config, :reverse_proxies).each do |proxy|
            reverse_proxy proxy[:downstream_url] => proxy[:path]
          end
        end
      end
    end

    include Equality
    extend Forwardable

    attr_reader :mappings, :reverse_proxies
    def_delegator :mappings, :sitehub_cookie_name

    def initialize(&block)
      @reverse_proxies = {}
      @mappings = Middleware::CandidateRouteMappings.new
      instance_eval(&block) if block
    end

    def build
      Middleware::ReverseProxy.new(mappings.init, reverse_proxies)
    end

    def proxy(opts = {}, &block)
      mapped_path, url = *(opts.respond_to?(:to_a) ? opts.to_a : [opts]).flatten

      mappings.add_route(url: url,
                         mapped_path: mapped_path,
                         &block)
    end

    def reverse_proxy(hash)
      reverse_proxies.merge!(hash)
    end
  end
end
