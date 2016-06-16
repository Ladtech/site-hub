require 'rack/request'
require 'sitehub/string_utils'
require 'sitehub/http_headers_object'
require 'sitehub/memoize'
class SiteHub
  class Request
    include Constants, Constants::HttpHeaderKeys

    extend Forwardable, Memoize

    def_delegator :@rack_request, :params
    def_delegator :@rack_request, :url
    def_delegator :@rack_request, :path
    def_delegator :@rack_request, :query_string

    attr_reader :env, :rack_request, :mapped_path, :mapped_url, :time

    def initialize(env:)
      @rack_request = Rack::Request.new(env)
      @env = HttpHeadersObject.from_rack_env(env)
      @time = Time.now
    end

    def map(path, url)
      @mapped_path = path
      @mapped_url = url
    end

    def request_method
      rack_request.request_method.downcase
    end

    def body
      rack_request.body.read
    end

    def headers
      @env.tap do |headers|
        # x-forwarded-for
        headers[X_FORWARDED_FOR_HEADER] = x_forwarded_for

        # x-forwarded-host
        headers[X_FORWARDED_HOST_HEADER] = x_forwarded_host
      end
    end

    def mapping
      RequestMapping.new(source_url: rack_request.url, mapped_url: mapped_url, mapped_path: mapped_path)
    end

    def mapped?
      mapped_path.is_a?(String)
    end

    def remote_user
      env[RackHttpHeaderKeys::REMOTE_USER]
    end

    def transaction_id
      env[HttpHeaderKeys::TRANSACTION_ID]
    end

    def http_version
      rack_request.env[RackHttpHeaderKeys::HTTP_VERSION]
    end

    def source_address
      rack_request.env[RackHttpHeaderKeys::X_FORWARDED_FOR] || rack_request.env[RackHttpHeaderKeys::REMOTE_ADDR]
    end

    def uri
      mapping.computed_uri
    end

    memoize :uri, :mapped?, :mapping, :headers, :body, :request_method

    private

    def remote_address
      rack_request.env[RackHttpHeaderKeys::REMOTE_ADDRESS_ENV_KEY]
    end

    def x_forwarded_host
      StringUtils.split(env[HttpHeaderKeys::X_FORWARDED_HOST_HEADER])
                 .push(env[HttpHeaderKeys::HOST_HEADER])
                 .join(COMMA)
    end

    def x_forwarded_for
      StringUtils.split(env[HttpHeaderKeys::X_FORWARDED_FOR_HEADER]).push(remote_address).join(COMMA)
    end
  end
end
