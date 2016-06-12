# rubocop:disable Metrics/ParameterLists
require 'sitehub/request'
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

    include Constants

    attr_reader :url, :id, :mapped_path, :http_client, :sitehub_cookie_path, :sitehub_cookie_name

    def initialize(url:, mapped_path: nil)
      @url = url
      @mapped_path = mapped_path
      @http_client = Faraday.new(ssl: { verify: false }) do |con|
        con.adapter :em_synchrony
      end
    end

    def call(env)
      request = Request.new(env)
      request_mapping = env[REQUEST_MAPPING] = request_mapping(request)

      proxy_call(request_mapping.computed_uri, request)
    rescue StandardError => exception
      env[ERRORS] << exception.message
      ERROR_RESPONSE.dup
    end

    def proxy_call(uri, sitehub_request)
      response = http_client.send(sitehub_request.request_method, uri) do |request|
        request.headers = sitehub_request.headers
        request.body = sitehub_request.body
        request.params = sitehub_request.params
      end

      Rack::Response.new(response.body, response.status,response.headers)
    end

    def request_mapping(source_request)
      RequestMapping.new(source_url: source_request.url, mapped_url: url, mapped_path: mapped_path)
    end

    def ==(other)
      other.is_a?(ForwardProxy) && self.url == other.url
    end
  end
end
