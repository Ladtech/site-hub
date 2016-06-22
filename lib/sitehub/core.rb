require 'sitehub/getter_setter_methods'
require 'sitehub/forward_proxy_builder'
require 'json-schema'

class SiteHub
  class InvalidProxyDefinitionException < Exception
  end


  module CollectionMethods
    def collection(hash, item)
      hash[item] || []
    end

    def collection!(hash, item)
      return hash[item] if hash[item]
      raise "missing: #{item}"
    end
  end

  class Core
    class << self
      def from_hash config
        new do
          extend CollectionMethods
          collection!(config, :proxies).each do |proxy|
            proxy(proxy[:path]) do
              extend CollectionMethods

              collection(proxy, :splits).each do |split|
                split(percentage: split[:percentage], url: split[:url], label: split[:label])
              end

              collection(proxy, :routes).each do |route|
                route(url: route[:url], label: route[:label])
              end

              default url: proxy[:default] if proxy[:default]
            end
          end

          collection(config, :reverse_proxies).each do |proxy|
            reverse_proxy proxy[:mapped_url] => proxy[:path]
          end
        end.build
      end
    end

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
