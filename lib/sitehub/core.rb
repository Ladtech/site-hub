require 'sitehub/forward_proxy_builder'
require 'json-schema'
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
      #TODO default action for missing key, throw exception?
      def from_hash config
        new do
          extend CollectionMethods
          sitehub_cookie_name config[:sitehub_cookie_name] if config[:sitehub_cookie_name]


          collection!(config, :proxies).each do |proxy|
            forward_proxies.add_proxy mapped_path: proxy[:mapped_path], proxy: ForwardProxyBuilder.from_hash(proxy, sitehub_cookie_name)
          end

          collection(config, :reverse_proxies).each do |proxy|
            reverse_proxy proxy[:downstream_url] => proxy[:path]
          end
        end
      end
    end

    include Equality
    extend Forwardable

    def_delegator :forward_proxies, :sitehub_cookie_name

    attr_reader :forward_proxies, :reverse_proxies

    def initialize(&block)
      @reverse_proxies = {}
      @forward_proxies = Middleware::ForwardProxies.new
      instance_eval(&block) if block
    end

    def build
      Middleware::ReverseProxy.new(forward_proxies.init, reverse_proxies)
    end

    def proxy(opts = {}, &block)
      mapped_path, url = *(opts.respond_to?(:to_a) ? opts.to_a : [opts]).flatten

      forward_proxies.add_proxy(url: url,
                                mapped_path: mapped_path,
                                &block)
    end

    def reverse_proxy(hash)
      reverse_proxies.merge!(hash)
    end
  end
end
