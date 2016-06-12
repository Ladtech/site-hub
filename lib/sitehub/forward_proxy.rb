# rubocop:disable Metrics/ParameterLists
require 'sitehub/http_headers'
require 'sitehub/string_sanitiser'
require 'sitehub/request_mapping'
require 'sitehub/rules'
require 'sitehub/resolver'
require 'faraday'
require 'sitehub/constants'

# Requirements: https://www.mnot.net/blog/2011/07/11/what_proxies_must_do
# 1. remove hop by hop headers
# 2. detect bad framing: where content length and content-encoding clash or are incorrect
# 3. fix conflicts between header and URL header
# 4. insert via (optional)
# 5. Expect header (optional)

class SiteHub
  class Request
    include StringSanitiser, Constants, HttpHeaders

    attr_reader :env, :rack_request
    extend Forwardable

    def_delegator :@rack_request, :params
    def_delegator :@rack_request, :url
    def_delegator :@rack_request, :path

    def initialize(env)
      @rack_request = Rack::Request.new(env)
      @env = filter_http_headers(extract_http_headers_from_rack_env(env))
    end

    def request_method
      @request_method ||= rack_request.request_method.downcase.to_sym
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

  class ForwardProxy
    ERROR_RESPONSE = Rack::Response.new(['error'], 500, {})

    include HttpHeaders, Rules, Resolver, Constants, StringSanitiser

    attr_reader :url, :id, :mapped_path, :http_client, :sitehub_cookie_path, :sitehub_cookie_name

    def initialize(url:, id:, mapped_path: nil, rule: nil, sitehub_cookie_path: nil, sitehub_cookie_name:)
      @id = id
      @url = url
      @rule = rule
      @mapped_path = mapped_path
      @sitehub_cookie_path = sitehub_cookie_path
      @sitehub_cookie_name = sitehub_cookie_name
      @http_client = Faraday.new(ssl: { verify: false }) do |con|
        con.adapter :em_synchrony
      end
    end

    def call(env)
      request = Request.new(env)
      request_mapping = env[REQUEST_MAPPING] = request_mapping(request)

      response(proxy_call(request_mapping.computed_uri, request), request)
    rescue StandardError => exception
      env[ERRORS] << exception.message
      ERROR_RESPONSE.dup
    end

    def proxy_call(uri, sitehub_request)
      http_client.send(sitehub_request.request_method, uri) do |request|
        request.headers = sitehub_request.headers
        request.body = sitehub_request.body
        request.params = sitehub_request.params
      end
    end

    def response(downstream_response, source_request)
      Rack::Response.new(downstream_response.body,
                         downstream_response.status,
                         downstream_response.headers).tap do |response|
        response.set_cookie(sitehub_cookie_name, path: (sitehub_cookie_path || source_request.path), value: id)
      end
    end

    def request_mapping(source_request)
      RequestMapping.new(source_url: source_request.url, mapped_url: url, mapped_path: mapped_path)
    end

    def ==(other)
      other.is_a?(ForwardProxy) && url == other.url
    end
  end
end
