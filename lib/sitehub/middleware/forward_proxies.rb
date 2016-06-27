require 'sitehub/constants'
require 'sitehub/nil_proxy'
require 'rack/request'
require 'rack/response'
require 'rack/utils'
require 'em-http'
require 'forwardable'

class SiteHub
  module Middleware
    class ForwardProxies < Hash
      NIL_PROXY = NilProxy.new

      attr_reader :sitehub_cookie_name

      def initialize(sitehub_cookie_name)
        @sitehub_cookie_name = sitehub_cookie_name
        self.default = NIL_PROXY
      end

      def call(env)
        source_request = Rack::Request.new(env)

        forward_proxy = mapped_proxy(path: source_request.path, request: source_request)

        forward_proxy.call(env)
      end

      def init
        values.each(&:build)
        self
      end

      def add_proxy(url: nil, mapped_path:, &block)
        self[mapped_path] = ForwardProxyBuilder.new(sitehub_cookie_name: sitehub_cookie_name,
                                                    url: url,
                                                    mapped_path: mapped_path,
                                                    &block)
      end

      def mapped_proxy(path:, request:)
        self[mapping(path)].resolve(id: request.cookies[sitehub_cookie_name], env: request.env)
      end

      def mapping(path)
        keys.find do |key|
          case key
          when Regexp
            key.match(path)
          else
            path == key
          end
        end
      end
    end
  end
end
