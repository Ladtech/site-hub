require 'sitehub/getter_setter_methods'
require 'sitehub/forward_proxy_builder'
require 'json-schema'

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
            forward_proxies << ForwardProxyBuilder.from_hash(proxy, sitehub_cookie_name)
          end

          collection(config, :reverse_proxies).each do |proxy|
            reverse_proxy proxy[:mapped_url] => proxy[:path]
          end
        end
      end
    end

    include Equality
    extend GetterSetterMethods


    getter_setter :sitehub_cookie_name, RECORDED_ROUTES_COOKIE
    attr_reader :forward_proxies, :reverse_proxies

    def initialize(&block)
      @forward_proxies = Middleware::ForwardProxies.new
      @reverse_proxies = {}
      instance_eval(&block) if block
    end

    def build
      Middleware::ReverseProxy.new(forward_proxies.init, reverse_proxies)
    end

    def proxy(opts = {}, &block)
      if opts.is_a?(Hash)
        mapped_path, url = *opts.to_a.flatten
      else
        mapped_path = opts
        url = nil
      end

      forward_proxies << ForwardProxyBuilder.new(sitehub_cookie_name: sitehub_cookie_name,
                                                 url: url,
                                                 mapped_path: mapped_path,
                                                 &block)
    end

    def reverse_proxy(hash)
      reverse_proxies.merge!(hash)
    end
  end
end
