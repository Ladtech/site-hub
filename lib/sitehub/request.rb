require 'rack/request'
require 'sitehub/string_sanitiser'
require 'sitehub/http_headers_object'

class SiteHub
  class Request
    include StringSanitiser, Constants, Constants::HttpHeaderKeys

    extend Forwardable

    def_delegator :@rack_request, :params
    def_delegator :@rack_request, :url
    def_delegator :@rack_request, :path

    attr_reader :env, :rack_request, :mapped_path, :mapped_url

    def initialize(env:, mapped_path:, mapped_url:)
      @rack_request = Rack::Request.new(env)
      @env = HttpHeadersObject.from_rack_env(env)
      @mapped_path = mapped_path
      @mapped_url = mapped_url
    end

    def request_method
      @request_method ||= rack_request.request_method.downcase
    end

    def body
      @body ||= rack_request.body.read
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

    def uri
      mapping.computed_uri
    end

    def ==(other)
      other.mapped_path == mapped_path &&
        other.mapped_url == mapped_url &&
        other.rack_request.env == rack_request.env
    end

    private

    def remote_address
      rack_request.env[RackHttpHeaderKeys::REMOTE_ADDRESS_ENV_KEY]
    end

    def x_forwarded_host
      split(env[HttpHeaderKeys::X_FORWARDED_HOST_HEADER])
        .push(env[HttpHeaderKeys::HOST_HEADER])
        .join(COMMA)
    end

    def x_forwarded_for
      split(env[HttpHeaderKeys::X_FORWARDED_FOR_HEADER]).push(remote_address).join(COMMA)
    end
  end
end
