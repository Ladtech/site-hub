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
      source_request = Rack::Request.new(env)
      request_mapping = env[REQUEST_MAPPING] = request_mapping(source_request)
      mapped_uri = URI(request_mapping.computed_uri)

      downstream_response = proxy_call(request_headers(mapped_uri, source_request.env), mapped_uri, source_request)

      response(downstream_response, source_request)
    rescue StandardError => e
      env[ERRORS] << e.message
      ERROR_RESPONSE.dup
    end

    def proxy_call(headers, mapped_uri, source_request)
      http_client.send(source_request.request_method.downcase, mapped_uri) do |request|
        request.headers = headers
        request.body = source_request.body.read
        request.params = source_request.params
      end
    end

    def response(response, source_request)
      Rack::Response.new(response.body, response.status, response.headers).tap do |r|
        r.set_cookie(sitehub_cookie_name, path: (sitehub_cookie_path || source_request.path), value: id)
      end
    end

    def request_headers(mapped_uri, source_env)
      filter_http_headers(extract_http_headers_from_rack_env(source_env)).tap do |headers|
        # HOST HEADERS
        headers[HOST_HEADER] = "#{mapped_uri.host}:#{mapped_uri.port}"

        # x-forwarded-for
        headers[X_FORWARDED_FOR_HEADER] = x_forwarded_for(source_env)

        # x-forwarded-host
        headers[X_FORWARDED_HOST_HEADER] = x_forwarded_host(source_env)
      end
    end

    def x_forwarded_host(source_env)
      split(source_env[RackHttpHeaderKeys::X_FORWARDED_HOST])
        .push(source_env[RackHttpHeaderKeys::HTTP_HOST])
        .join(',')
    end

    def x_forwarded_for(headers)
      split(headers[X_FORWARDED_FOR_HEADER]).push(remote_address(headers)).join(COMMA)
    end

    def remote_address(env)
      env[RackHttpHeaderKeys::REMOTE_ADDRESS_ENV_KEY]
    end

    def request_mapping(source_request)
      RequestMapping.new(source_url: source_request.url, mapped_url: url, mapped_path: mapped_path)
    end

    def ==(other)
      other.is_a?(ForwardProxy) && url == other.url
    end
  end
end
